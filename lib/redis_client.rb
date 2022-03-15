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

  attr_reader :host, :port, :ssl, :path
  attr_accessor :connect_timeout, :read_timeout, :write_timeout

  def initialize(
    host: "localhost",
    port: 6379,
    path: nil,
    username: nil,
    password: nil,
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
    @ssl = ssl
    @ssl_params = ssl_params
    @raw_connection = nil
    @connect_timeout = connect_timeout
    @read_timeout = read_timeout
    @write_timeout = write_timeout
  end

  def timeout=(timeout)
    @connect_timeout = @read_timeout = @write_timeout = timeout
  end

  def call(*command)
    query = RESP3.dump(RESP3.coerce_command!(command))
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

  def close
    @raw_connection&.close
    @raw_connection = nil
    self
  end

  def pipelined
    commands = []
    yield Pipeline.new(commands)
    call_pipelined(commands)
  end

  def multi(watch: nil)
    call("WATCH", *watch) if watch

    commands = []
    yield Pipeline.new(commands)
    call_pipelined([["MULTI"], *commands, ["EXEC"]]).last
  rescue
    call("UNWATCH") if watch
    raise
  end

  def call_pipelined(commands)
    exception = nil
    commands.map! { |c| RESP3.coerce_command!(c) }
    query = RESP3.dump_all(commands)

    results = handle_network_errors do
      raw_connection.write(query)
      commands.map do
        result = RESP3.load(raw_connection)
        if result.is_a?(CommandError)
          exception ||= result
        end
        result
      end
    end

    if exception
      raise exception
    else
      results
    end
  end

  class Pipeline
    def initialize(commands)
      @commands = commands
    end

    def call(*command)
      @commands << RESP3.coerce_command!(command)
      nil
    end
  end

  class Transaction < Pipeline
    def commands
      [["MULTI"], *@commands, ["EXEC"]]
    end
  end

  private

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

    if @password
      call("HELLO", "3", "AUTH", @username, @password)
    else
      call("HELLO", "3")
    end

    @raw_connection
  end

  def new_socket
    socket = if path
      UNIXSocket.new(path)
    else
      Socket.tcp(host, port, connect_timeout: connect_timeout)
    end

    if ssl
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.set_params(@ssl_params || {})
      socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
      socket.hostname = host
      loop do
        case status = socket.connect_nonblock(exception: false)
        when :wait_readable
          socket.to_io.wait_readable(@connect_timeout) or raise ReadTimeoutError
        when :wait_writable
          socket.to_io.wait_writable(@connect_timeout) or raise WriteTimeoutError
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
