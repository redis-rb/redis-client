# frozen_string_literal: true

require "test_helper"

class RedisPooledClientTest < RedisClientTestCase
  include ClientTestHelper
  include RedisClientTests

  def test_checkout_timeout
    pool = RedisClient.config(**tcp_config).new_pool(size: 1, timeout: 0.01)
    Thread.new { pool.instance_variable_get(:@pool).checkout }.join

    error = assert_raises RedisClient::ConnectionError do
      pool.with {}
    end
    assert_includes error.message, "Couldn't checkout a connection in time: Waited 0.01 sec"
  end

  def test_idle_timeout_closes_stale_connections
    pool = RedisClient.config(**tcp_config).new_pool(size: 1, idle_timeout: 10)
    pool.call("PING")

    travel(11) do
      assert_equal "PONG", pool.call("PING")
    end
  end

  def test_idle_timeout_does_not_close_fresh_connections
    pool = RedisClient.config(**tcp_config).new_pool(size: 1, idle_timeout: 10)
    pool.call("PING")

    travel(5) do
      assert_equal "PONG", pool.call("PING")
    end
  end

  def test_idle_timeout_nil_by_default
    pool = RedisClient.config(**tcp_config).new_pool(size: 1)
    pool.call("PING")

    travel(9999) do
      assert_equal "PONG", pool.call("PING")
    end
  end

  private

  def new_client(**overrides)
    RedisClient.config(**tcp_config.merge(overrides)).new_pool
  end
end
