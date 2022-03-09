# frozen_string_literal: true

require "socket"
require "redis_client/version"
require "redis_client/resp3"

class RedisClient
  def initialize
    @host = "localhost"
    @port = 6379
    @raw_connection = nil
  end

  def call(*command)
    raw_connection.write_nonblock(RESP3.dump(command), exception: false)
    raw_connection.wait_readable
    RESP3.load(raw_connection.read_nonblock(100, exception: false))
  end

  private

  def raw_connection
    @raw_connection ||= TCPSocket.new(@host, @port)
  end
end
