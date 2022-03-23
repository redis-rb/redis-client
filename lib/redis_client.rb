# frozen_string_literal: true

require "socket"
require "openssl"
require "redis_client/version"
require "redis_client/buffered_io"

class RedisClient
  DEFAULT_TIMEOUT = 3

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

  class Config
    attr_reader :host, :port, :db, :username, :password, :id, :ssl, :ssl_params, :path,
      :connect_timeout, :read_timeout, :write_timeout

    def initialize(
      host: "localhost",
      port: 6379,
      path: nil,
      username: nil,
      password: nil,
      db: nil,
      id: nil,
      timeout: DEFAULT_TIMEOUT,
      read_timeout: timeout,
      write_timeout: timeout,
      connect_timeout: timeout,
      ssl: false,
      ssl_params: nil
    )
      @host = host
      @port = port
      @path = path
      @username = username || "default"
      @password = password
      @db = db
      @id = id
      @ssl = ssl
      @ssl_params = ssl_params
      @connect_timeout = connect_timeout
      @read_timeout = read_timeout
      @write_timeout = write_timeout
    end

    def new_client(**kwargs)
      RedisClient.new(self, **kwargs)
    end
  end

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
  end

  def timeout=(timeout)
    @connect_timeout = @read_timeout = @write_timeout = timeout
  end

  def pubsub
    sub = PubSub.new(raw_connection)
    @raw_connection = nil
    sub
  end

  def call(*command)
    query = RESP3.dump(command)
    result = handle_network_errors do
      raw_connection.write(query)
      RESP3.load(raw_connection)
    end
    if result.is_a?(CommandError)
      raise result
    else
      result
    end
  end

  def blocking_call(timeout, *command)
    raw_connection.with_timeout(timeout) do
      call(*command)
    end
  rescue ReadTimeoutError
    nil
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
      call_pipelined(pipeline)
    end
  end

  def multi(watch: nil)
    call("WATCH", *watch) if watch

    transaction = Multi.new
    transaction.call("MULTI")
    yield transaction
    transaction.call("EXEC")
    call_pipelined(transaction).last
  rescue
    call("UNWATCH") if watch
    raise
  end

  class PubSub
    def initialize(raw_connection)
      @raw_connection = raw_connection
    end

    def call(*command)
      query = RESP3.dump(command)
      raw_connection.write(query)
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

      if timeout
        raw_connection.with_timeout(timeout) do
          RESP3.load(raw_connection)
        end
      else
        RESP3.load(raw_connection)
      end
    rescue ReadTimeoutError
      nil
    end

    private

    attr_reader :raw_connection
  end

  class Multi
    def initialize
      @size = 0
      @buffer = nil
    end

    def call(*command)
      @buffer = RESP3.dump(command, @buffer)
      @size += 1
      nil
    end

    def _buffer
      @buffer
    end

    def _size
      @size
    end

    def _timeout(_index)
      nil
    end
  end

  class Pipeline < Multi
    def initialize
      super
      @timeouts = nil
    end

    def blocking_call(timeout, *command)
      @timeouts ||= []
      @timeouts[@size] = timeout
      call(*command)
    end

    def _timeout(index)
      @timeouts[index] if @timeouts
    end
  end

  private

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

  def call_pipelined(pipeline)
    exception = nil

    results = Array.new(pipeline._size)
    handle_network_errors do
      raw_connection.write(pipeline._buffer)

      pipeline._size.times do |index|
        timeout = pipeline._timeout(index)
        result = if timeout.nil?
          RESP3.load(raw_connection)
        else
          raw_connection.with_timeout(timeout) do
            RESP3.load(raw_connection)
          end
        end
        if result.is_a?(CommandError)
          exception ||= result
        end
        results[index] = result
      end
    end

    if exception
      raise exception
    else
      results
    end
  end

  def handle_network_errors
    yield
  rescue SystemCallError => error
    close
    raise ConnectionError, error.message, error.backtrace
  rescue ConnectionError
    close
    raise
  end

  def raw_connection
    return @raw_connection if @raw_connection

    @raw_connection = BufferedIO.new(
      new_socket,
      read_timeout: read_timeout,
      write_timeout: write_timeout,
    )

    pipelined do |pipeline|
      if config.password
        pipeline.call("HELLO", "3", "AUTH", config.username, config.password)
      else
        pipeline.call("HELLO", "3")
      end

      if id
        pipeline.call("CLIENT", "SETNAME", id)
      end

      if config.db
        pipeline.call("SELECT", config.db)
      end
    end

    @raw_connection
  end

  def new_socket
    socket = if config.path
      UNIXSocket.new(config.path)
    else
      sock = Socket.tcp(config.host, config.port, connect_timeout: connect_timeout)
      # disables Nagle's Algorithm, prevents multiple round trips with MULTI
      sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      sock
    end

    if config.ssl
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.set_params(config.ssl_params || {})
      socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
      socket.hostname = config.host
      loop do
        case status = socket.connect_nonblock(exception: false)
        when :wait_readable
          socket.to_io.wait_readable(connect_timeout) or raise ReadTimeoutError
        when :wait_writable
          socket.to_io.wait_writable(connect_timeout) or raise WriteTimeoutError
        when socket
          break
        else
          raise "Unexpected `connect_nonblock` return: #{status.inspect}"
        end
      end
    end

    socket
  rescue Errno::ETIMEDOUT => error
    raise ConnectTimeoutError, error.message
  rescue SystemCallError => error
    raise ConnectionError, error.message
  end
end

require "redis_client/resp3"
