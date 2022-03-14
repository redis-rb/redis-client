# frozen_string_literal: true

require "socket"
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

  CommandError = Class.new(Error)

  attr_reader :host, :post
  attr_accessor :connect_timeout, :read_timeout, :write_timeout

  def initialize(
    host: "localhost",
    port: 6379,
    timeout: DEFAULT_TIMEOUT,
    read_timeout: timeout,
    write_timeout: timeout,
    connect_timeout: timeout
  )
    @host = host
    @port = port
    @raw_connection = nil
    @connect_timeout = connect_timeout
    @read_timeout = read_timeout
    @write_timeout = write_timeout
  end

  def timeout=(timeout)
    @connect_timeout = @read_timeout = @write_timeout = timeout
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

  def call_pipelined(commands)
    exception = nil
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
      @commands << command
      nil
    end
  end

  private

  def handle_network_errors
    yield
  rescue SystemCallError => error
    close
    raise ConnectionError, error.message
  rescue ConnectionError
    close
    raise
  end

  def raw_connection
    @raw_connection ||= BufferedIO.new(
      new_socket,
      read_timeout: @read_timeout,
      write_timeout: @write_timeout,
    )
  end

  def new_socket
    Socket.tcp(@host, @port, connect_timeout: @connect_timeout)
  rescue Errno::ETIMEDOUT
    raise ConnectTimeoutError, error.message
  rescue SystemCallError => error
    raise ConnectionError, error.message
  end
end

require "redis_client/resp3"
