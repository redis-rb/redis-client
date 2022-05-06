# frozen_string_literal: true

require_relative "../test_helper"

# See: https://github.com/redis-rb/redis-client/issues/16
# The hiredis-rb gems expose all hiredis symbols, so we must be careful
# about how we link against it.
require "redis"
require "hiredis"
Redis.new(host: Servers::HOST, port: Servers::REDIS_TCP_PORT, driver: :hiredis).ping
require "hiredis-client"

unless RedisClient.default_driver == RedisClient::HiredisConnection
  abort("Hiredis not defined as default driver")
end

begin
  # This method was added in Ruby 3.0.0. Calling it this way asks the GC to
  # move objects around, helping to find object movement bugs.
  GC.verify_compaction_references(double_heap: true, toward: :empty)
rescue NoMethodError
end
