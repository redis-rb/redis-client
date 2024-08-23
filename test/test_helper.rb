# frozen_string_literal: true

require_relative "env"

Servers.build_redis
Servers::SENTINEL_TESTS.shutdown
Servers::TESTS.prepare

require "minitest/autorun"

at_exit { $stderr.puts "Running test suite with driver: #{RedisClient.default_driver}" }

unless ENV["REDIS_CLIENT_RESTART_SERVER"] == "0"
  Minitest.after_run { Servers::TESTS.shutdown }
end

class RedisClientTestCase < Minitest::Test
end
