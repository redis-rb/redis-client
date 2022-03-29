# frozen_string_literal: true

require "redis_client/version"
require "redis_client/config"
require "redis_client/connection"

class RedisClient
  Error = Class.new(StandardError)

  ConnectionError = Class.new(Error)
  TimeoutError = Class.new(ConnectionError)
  ReadTimeoutError = Class.new(TimeoutError)
  WriteTimeoutError = Class.new(TimeoutError)
  ConnectTimeoutError = Class.new(TimeoutError)

  class CommandError < Error
    class << self
      def parse(error_message)
        code = error_message.split(' ', 2).first
        klass = ERRORS.fetch(code, self)
        klass.new(error_message)
      end
    end
  end

  AuthenticationError = Class.new(CommandError)
  PermissionError = Class.new(CommandError)

  CommandError::ERRORS = {
    "WRONGPASS" => AuthenticationError,
    "NOPERM" => PermissionError,
  }.freeze

  class << self
    def config(**kwargs)
      Config.new(**kwargs)
    end

    def new(arg = nil, **kwargs)
      if arg.is_a?(Config)
        super
      else
        super(config(**(arg || {}), **kwargs))
      end
    end
  end

  attr_reader :config, :id
  attr_accessor :connect_timeout, :read_timeout, :write_timeout

  def initialize(
    config,
    id: config.id,
    connect_timeout: config.connect_timeout,
    read_timeout: config.read_timeout,
    write_timeout: config.write_timeout
  )
    @config = config
    @id = id
    @connect_timeout = connect_timeout
    @read_timeout = read_timeout
    @write_timeout = write_timeout
    @raw_connection = nil
    @disable_reconnection = false
  end

  def timeout=(timeout)
    @connect_timeout = @read_timeout = @write_timeout = timeout
  end

  def pubsub
    sub = PubSub.new(ensure_connected)
    @raw_connection = nil
    sub
  end

  def call(*command)
    command = RESP3.coerce_command!(command)
    result = ensure_connected do |connection|
      connection.write(command)
      connection.read
    end

    if result.is_a?(CommandError)
      raise result
    else
      result
    end
  end

  def call_once(*command)
    command = RESP3.coerce_command!(command)
    result = ensure_connected(retryable: false) do |connection|
      connection.write(command)
      connection.read
    end

    if result.is_a?(CommandError)
      raise result
    else
      result
    end
  end

  def blocking_call(timeout, *command)
    command = RESP3.coerce_command!(command)
    result = ensure_connected do |connection|
      connection.write(command)
      connection.read(timeout)
    end

    if result.is_a?(CommandError)
      raise result
    else
      result
    end
  end

  def scan(*args, &block)
    unless block_given?
      return to_enum(__callee__, *args)
    end

    scan_list(1, ["SCAN", 0, *args], &block)
  end

  def sscan(key, *args, &block)
    unless block_given?
      return to_enum(__callee__, key, *args)
    end

    scan_list(2, ["SSCAN", key, 0, *args], &block)
  end

  def hscan(key, *args, &block)
    unless block_given?
      return to_enum(__callee__, key, *args)
    end

    scan_pairs(2, ["HSCAN", key, 0, *args], &block)
  end

  def zscan(key, *args, &block)
    unless block_given?
      return to_enum(__callee__, key, *args)
    end

    scan_pairs(2, ["ZSCAN", key, 0, *args], &block)
  end

  def connected?
    @raw_connection&.connected?
  end

  def close
    @raw_connection&.close
    @raw_connection = nil
    self
  end

  def pipelined
    pipeline = Pipeline.new
    yield pipeline

    if pipeline._size == 0
      []
    else
      ensure_connected(retryable: pipeline._retryable?) do |connection|
        call_pipelined(connection, pipeline._commands, pipeline._timeouts)
      end
    end
  end

  def multi(watch: nil, &block)
    if watch
      # WATCH is stateful, so we can't reconnect if it's used, the whole transaction
      # has to be redone.
      ensure_connected(retryable: false) do |connection|
        call("WATCH", *watch)
        begin
          if transaction = build_transaction(&block)
            call_pipelined(connection, transaction._commands).last
          else
            call("UNWATCH")
            []
          end
        rescue
          call("UNWATCH") if connected? && watch
          raise
        end
      end
    else
      transaction = build_transaction(&block)
      if transaction._empty?
        []
      else
        ensure_connected(retryable: transaction._retryable?) do |connection|
          call_pipelined(connection, transaction._commands).last
        end
      end
    end
  end

  class PubSub
    def initialize(raw_connection)
      @raw_connection = raw_connection
    end

    def call(*command)
      raw_connection.write(RESP3.coerce_command!(command))
      nil
    end

    def close
      raw_connection&.close
      @raw_connection = nil
      self
    end

    def next_event(timeout = nil)
      unless raw_connection
        raise ConnectionError, "Connection was closed or lost"
      end

      raw_connection.read(timeout)
    rescue ReadTimeoutError
      nil
    end

    private

    attr_reader :raw_connection
  end

  class Multi
    def initialize
      @size = 0
      @commands = []
      @retryable = true
    end

    def call(*command)
      @commands << RESP3.coerce_command!(command)
      nil
    end

    def call_once(*command)
      @retryable = false
      @commands << RESP3.coerce_command!(command)
      nil
    end

    def _commands
      @commands
    end

    def _size
      @commands.size
    end

    def _empty?
      @commands.size <= 2
    end

    def _timeouts
      nil
    end

    def _retryable?
      @retryable
    end
  end

  class Pipeline < Multi
    def initialize
      super
      @timeouts = nil
    end

    def blocking_call(timeout, *command)
      @timeouts ||= []
      @timeouts[@commands.size] = timeout
      @commands << RESP3.coerce_command!(command)
      nil
    end

    def _timeouts
      @timeouts
    end

    def _empty?
      @commands.empty?
    end
  end

  private

  def build_transaction
    transaction = Multi.new
    transaction.call("MULTI")
    yield transaction
    transaction.call("EXEC")
    transaction
  end

  def scan_list(cursor_index, command, &block)
    cursor = 0
    while cursor != "0"
      command[cursor_index] = cursor
      cursor, elements = call(*command)
      elements.each(&block)
    end
    nil
  end

  def scan_pairs(cursor_index, command)
    cursor = 0
    while cursor != "0"
      command[cursor_index] = cursor
      cursor, elements = call(*command)

      index = 0
      size = elements.size
      while index < size
        yield elements[index], elements[index + 1]
        index += 2
      end
    end
    nil
  end

  def call_pipelined(connection, commands, timeouts = nil)
    exception = nil

    size = commands.size
    results = Array.new(commands.size)
    connection.write_multi(commands)

    size.times do |index|
      timeout = timeouts && timeouts[index]
      result = connection.read(timeout)
      if result.is_a?(CommandError)
        exception ||= result
      end
      results[index] = result
    end

    if exception
      raise exception
    else
      results
    end
  end

  def ensure_connected(retryable: true)
    if retryable
      tries = 0
      connection = nil
      begin
        connection = raw_connection
        if block_given?
          yield connection
        else
          connection
        end
      rescue ConnectionError
        connection&.close
        close

        if !@disable_reconnection && config.retry_connecting?(tries)
          tries += 1
          retry
        else
          raise
        end
      end
    else
      previous_disable_reconnection = @disable_reconnection
      connection = ensure_connected
      begin
        @disable_reconnection = true
        yield connection
      ensure
        @disable_reconnection = previous_disable_reconnection
      end
    end
  end

  def raw_connection
    @raw_connection ||= begin
      connection = config.driver.new(
        config,
        connect_timeout: connect_timeout,
        read_timeout: read_timeout,
        write_timeout: write_timeout,
      )

      prelude = config.connection_prelude
      if id
        prelude = prelude.dup
        prelude << ["CLIENT", "SETNAME", id.to_s]
      end
      call_pipelined(connection, prelude)
      connection
    end
  end
end

require "redis_client/resp3"
