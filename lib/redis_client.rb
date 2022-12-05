# frozen_string_literal: true

require "redis_client/version"
require "redis_client/command_builder"
require "redis_client/config"
require "redis_client/sentinel_config"
require "redis_client/middlewares"

class RedisClient
  @driver_definitions = {}
  @drivers = {}

  @default_driver = nil

  class << self
    def register_driver(name, &block)
      @driver_definitions[name] = block
    end

    def driver(name)
      return name if name.is_a?(Class)

      name = name.to_sym
      unless @driver_definitions.key?(name)
        raise ArgumentError, "Unknown driver #{name.inspect}, expected one of: `#{@driver_definitions.keys.inspect}`"
      end

      @drivers[name] ||= @driver_definitions[name]&.call
    end

    def default_driver
      unless @default_driver
        @driver_definitions.each_key do |name|
          if @default_driver = driver(name)
            break
          end
        rescue LoadError
        end
      end
      @default_driver
    end

    def default_driver=(name)
      @default_driver = driver(name)
    end
  end

  register_driver :ruby do
    require "redis_client/ruby_connection"
    RubyConnection
  end

  module Common
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
      @id = id&.to_s
      @connect_timeout = connect_timeout
      @read_timeout = read_timeout
      @write_timeout = write_timeout
      @command_builder = config.command_builder
      @pid = Process.pid
    end

    def timeout=(timeout)
      @connect_timeout = @read_timeout = @write_timeout = timeout
    end
  end

  Error = Class.new(StandardError)

  ProtocolError = Class.new(Error)
  UnsupportedServer = Class.new(Error)

  ConnectionError = Class.new(Error)
  CannotConnectError = Class.new(ConnectionError)

  FailoverError = Class.new(ConnectionError)

  TimeoutError = Class.new(ConnectionError)
  ReadTimeoutError = Class.new(TimeoutError)
  WriteTimeoutError = Class.new(TimeoutError)
  CheckoutTimeoutError = Class.new(TimeoutError)

  module HasCommand
    attr_reader :command

    def _set_command(command)
      @command = command
    end
  end

  class CommandError < Error
    include HasCommand

    class << self
      def parse(error_message)
        code = if error_message.start_with?("ERR Error running script")
          # On older redis servers script errors are nested.
          # So we need to parse some more.
          if (match = error_message.match(/:\s-([A-Z]+) /))
            match[1]
          end
        end
        code ||= error_message.split(' ', 2).first
        klass = ERRORS.fetch(code, self)
        klass.new(error_message)
      end
    end
  end

  AuthenticationError = Class.new(CommandError)
  PermissionError = Class.new(CommandError)
  WrongTypeError = Class.new(CommandError)
  OutOfMemoryError = Class.new(CommandError)

  ReadOnlyError = Class.new(ConnectionError)
  ReadOnlyError.include(HasCommand)

  MasterDownError = Class.new(ConnectionError)
  MasterDownError.include(HasCommand)

  CommandError::ERRORS = {
    "WRONGPASS" => AuthenticationError,
    "NOPERM" => PermissionError,
    "READONLY" => ReadOnlyError,
    "MASTERDOWN" => MasterDownError,
    "WRONGTYPE" => WrongTypeError,
    "OOM" => OutOfMemoryError,
  }.freeze

  class << self
    def config(**kwargs)
      Config.new(client_implementation: self, **kwargs)
    end

    def sentinel(**kwargs)
      SentinelConfig.new(client_implementation: self, **kwargs)
    end

    def new(arg = nil, **kwargs)
      if arg.is_a?(Config::Common)
        super
      else
        super(config(**(arg || {}), **kwargs))
      end
    end

    def register(middleware)
      Middlewares.include(middleware)
    end
  end

  include Common

  def initialize(config, **)
    super
    @middlewares = config.middlewares_stack.new(self)
    @raw_connection = nil
    @disable_reconnection = false
  end

  def inspect
    id_string = " id=#{id}" if id
    "#<#{self.class.name} #{config.server_url}#{id_string}>"
  end

  def size
    1
  end

  def with(_options = nil)
    yield self
  end
  alias_method :then, :with

  def timeout=(timeout)
    super
    raw_connection.read_timeout = raw_connection.write_timeout = timeout if connected?
  end

  def read_timeout=(timeout)
    super
    raw_connection.read_timeout = timeout if connected?
  end

  def write_timeout=(timeout)
    super
    raw_connection.write_timeout = timeout if connected?
  end

  def pubsub
    sub = PubSub.new(ensure_connected, @command_builder)
    @raw_connection = nil
    sub
  end

  def call(*command, **kwargs)
    command = @command_builder.generate(command, kwargs)
    result = ensure_connected do |connection|
      @middlewares.call(command, config) do
        connection.call(command, nil)
      end
    end

    if block_given?
      yield result
    else
      result
    end
  end

  def call_v(command)
    command = @command_builder.generate(command)
    result = ensure_connected do |connection|
      @middlewares.call(command, config) do
        connection.call(command, nil)
      end
    end

    if block_given?
      yield result
    else
      result
    end
  end

  def call_once(*command, **kwargs)
    command = @command_builder.generate(command, kwargs)
    result = ensure_connected(retryable: false) do |connection|
      @middlewares.call(command, config) do
        connection.call(command, nil)
      end
    end

    if block_given?
      yield result
    else
      result
    end
  end

  def call_once_v(command)
    command = @command_builder.generate(command)
    result = ensure_connected(retryable: false) do |connection|
      @middlewares.call(command, config) do
        connection.call(command, nil)
      end
    end

    if block_given?
      yield result
    else
      result
    end
  end

  def blocking_call(timeout, *command, **kwargs)
    command = @command_builder.generate(command, kwargs)
    error = nil
    result = ensure_connected do |connection|
      @middlewares.call(command, config) do
        connection.call(command, timeout)
      end
    rescue ReadTimeoutError => error
      break
    end

    if error
      raise error
    elsif block_given?
      yield result
    else
      result
    end
  end

  def blocking_call_v(timeout, command)
    command = @command_builder.generate(command)
    error = nil
    result = ensure_connected do |connection|
      @middlewares.call(command, config) do
        connection.call(command, timeout)
      end
    rescue ReadTimeoutError => error
      break
    end

    if error
      raise error
    elsif block_given?
      yield result
    else
      result
    end
  end

  def scan(*args, **kwargs, &block)
    unless block_given?
      return to_enum(__callee__, *args, **kwargs)
    end

    args = @command_builder.generate(["SCAN", 0] + args, kwargs)
    scan_list(1, args, &block)
  end

  def sscan(key, *args, **kwargs, &block)
    unless block_given?
      return to_enum(__callee__, key, *args, **kwargs)
    end

    args = @command_builder.generate(["SSCAN", key, 0] + args, kwargs)
    scan_list(2, args, &block)
  end

  def hscan(key, *args, **kwargs, &block)
    unless block_given?
      return to_enum(__callee__, key, *args, **kwargs)
    end

    args = @command_builder.generate(["HSCAN", key, 0] + args, kwargs)
    scan_pairs(2, args, &block)
  end

  def zscan(key, *args, **kwargs, &block)
    unless block_given?
      return to_enum(__callee__, key, *args, **kwargs)
    end

    args = @command_builder.generate(["ZSCAN", key, 0] + args, kwargs)
    scan_pairs(2, args, &block)
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
    pipeline = Pipeline.new(@command_builder)
    yield pipeline

    if pipeline._size == 0
      []
    else
      results = ensure_connected(retryable: pipeline._retryable?) do |connection|
        commands = pipeline._commands
        @middlewares.call_pipelined(commands, config) do
          connection.call_pipelined(commands, pipeline._timeouts)
        end
      end

      pipeline._coerce!(results)
    end
  end

  def multi(watch: nil, &block)
    transaction = nil

    results = if watch
      # WATCH is stateful, so we can't reconnect if it's used, the whole transaction
      # has to be redone.
      ensure_connected(retryable: false) do |connection|
        call("WATCH", *watch)
        begin
          if transaction = build_transaction(&block)
            commands = transaction._commands
            results = @middlewares.call_pipelined(commands, config) do
              connection.call_pipelined(commands, nil)
            end.last
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
          commands = transaction._commands
          @middlewares.call_pipelined(commands, config) do
            connection.call_pipelined(commands, nil)
          end.last
        end
      end
    end

    if transaction
      transaction._coerce!(results)
    else
      results
    end
  end

  class PubSub
    def initialize(raw_connection, command_builder)
      @raw_connection = raw_connection
      @command_builder = command_builder
    end

    def call(*command, **kwargs)
      raw_connection.write(@command_builder.generate(command, kwargs))
      nil
    end

    def call_v(command)
      raw_connection.write(@command_builder.generate(command))
      nil
    end

    def close
      @raw_connection&.close
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
    def initialize(command_builder)
      @command_builder = command_builder
      @size = 0
      @commands = []
      @blocks = nil
      @retryable = true
    end

    def call(*command, **kwargs, &block)
      command = @command_builder.generate(command, kwargs)
      (@blocks ||= [])[@commands.size] = block if block_given?
      @commands << command
      nil
    end

    def call_v(command, &block)
      command = @command_builder.generate(command)
      (@blocks ||= [])[@commands.size] = block if block_given?
      @commands << command
      nil
    end

    def call_once(*command, **kwargs, &block)
      command = @command_builder.generate(command, kwargs)
      @retryable = false
      (@blocks ||= [])[@commands.size] = block if block_given?
      @commands << command
      nil
    end

    def call_once_v(command, &block)
      command = @command_builder.generate(command)
      @retryable = false
      (@blocks ||= [])[@commands.size] = block if block_given?
      @commands << command
      nil
    end

    def _commands
      @commands
    end

    def _blocks
      @blocks
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

    def _coerce!(results)
      results&.each_with_index do |result, index|
        if result.is_a?(CommandError)
          result._set_command(@commands[index + 1])
          raise result
        end

        if @blocks && block = @blocks[index + 1]
          results[index] = block.call(result)
        end
      end

      results
    end
  end

  class Pipeline < Multi
    def initialize(_command_builder)
      super
      @timeouts = nil
    end

    def blocking_call(timeout, *command, **kwargs, &block)
      command = @command_builder.generate(command, kwargs)
      @timeouts ||= []
      @timeouts[@commands.size] = timeout
      (@blocks ||= [])[@commands.size] = block if block_given?
      @commands << command
      nil
    end

    def blocking_call_v(timeout, command, &block)
      command = @command_builder.generate(command)
      @timeouts ||= []
      @timeouts[@commands.size] = timeout
      (@blocks ||= [])[@commands.size] = block if block_given?
      @commands << command
      nil
    end

    def _timeouts
      @timeouts
    end

    def _empty?
      @commands.empty?
    end

    def _coerce!(results)
      return results unless results

      @blocks&.each_with_index do |block, index|
        if block
          results[index] = block.call(results[index])
        end
      end

      results
    end
  end

  private

  def build_transaction
    transaction = Multi.new(@command_builder)
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

  def ensure_connected(retryable: true)
    close if !config.inherit_socket && @pid != Process.pid

    if @disable_reconnection
      if block_given?
        yield @raw_connection
      else
        @raw_connection
      end
    elsif retryable
      tries = 0
      connection = nil
      begin
        connection = raw_connection
        if block_given?
          yield connection
        else
          connection
        end
      rescue ConnectionError, ProtocolError => error
        close

        if !@disable_reconnection && config.retry_connecting?(tries, error)
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
      rescue ConnectionError, ProtocolError
        close
        raise
      ensure
        @disable_reconnection = previous_disable_reconnection
      end
    end
  end

  def raw_connection
    @raw_connection = @raw_connection&.revalidate
    @raw_connection ||= connect
  end

  def connect
    @pid = Process.pid

    connection = @middlewares.connect(config) do
      config.driver.new(
        config,
        connect_timeout: connect_timeout,
        read_timeout: read_timeout,
        write_timeout: write_timeout,
      )
    end

    prelude = config.connection_prelude.dup

    if id
      prelude << ["CLIENT", "SETNAME", id]
    end

    # The connection prelude is deliberately not sent to Middlewares
    if config.sentinel?
      prelude << ["ROLE"]
      role, = @middlewares.call_pipelined(prelude, config) do
        connection.call_pipelined(prelude, nil).last
      end
      config.check_role!(role)
    else
      unless prelude.empty?
        @middlewares.call_pipelined(prelude, config) do
          connection.call_pipelined(prelude, nil)
        end
      end
    end

    connection
  rescue FailoverError, CannotConnectError
    raise
  rescue ConnectionError => error
    raise CannotConnectError, error.message, error.backtrace
  rescue CommandError => error
    if error.message.match?(/ERR unknown command ['`]HELLO['`]/)
      raise UnsupportedServer,
        "redis-client requires Redis 6+ with HELLO command available (#{config.server_url})"
    else
      raise
    end
  end
end

require "redis_client/pooled"
require "redis_client/circuit_breaker"

RedisClient.default_driver
