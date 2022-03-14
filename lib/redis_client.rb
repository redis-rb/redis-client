# frozen_string_literal: true

require "socket"
require "redis_client/version"
require "redis_client/buffered_io"

class RedisClient
  Error = Class.new(StandardError)
  TimeoutError = Class.new(Error)
  ReadTimeoutError = Class.new(TimeoutError)
  WriteTimeoutError = Class.new(TimeoutError)
  CommandError = Class.new(Error)

  def initialize(host: nil, port: nil)
    @host = host || "localhost"
    @port = port || 6379
    @raw_connection = nil
    @read_timeout = 5
    @write_timeout = 5
    @open_timeout = 5
  end

  def call(*command)
    raw_connection.write(RESP3.dump(command))
    result = RESP3.load(raw_connection)
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
    raw_connection.write(RESP3.dump_all(commands))
    exception = nil
    results = commands.map do
      result = RESP3.load(raw_connection)
      if result.is_a?(CommandError)
        exception ||= result
      end
      result
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

  def raw_connection
    @raw_connection ||= BufferedIO.new(
      TCPSocket.new(@host, @port),
      read_timeout: @read_timeout,
      write_timeout: @write_timeout,
    )
  end
end

require "redis_client/resp3"
