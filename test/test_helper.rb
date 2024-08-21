# frozen_string_literal: true

require_relative "env"

Servers.build_redis
Servers::SENTINEL_TESTS.shutdown
Servers.all = Servers::TESTS

class RedisClientTestCase < Megatest::Test
end
