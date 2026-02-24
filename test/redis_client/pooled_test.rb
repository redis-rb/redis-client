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

  def test_idle_timeout_revalidates_stale_connections
    pool = RedisClient.config(**tcp_config).new_pool(size: 1, idle_timeout: 10)
    pool.call("PING")

    travel(11) do
      assert_equal "PONG", pool.call("PING")
    end
  end

  def test_idle_timeout_reuses_valid_connection
    pool = RedisClient.config(**tcp_config).new_pool(size: 1, idle_timeout: 10)

    # Capture the underlying raw connection
    raw_connection_id = nil
    pool.with do |client|
      client.call("PING")
      raw_connection_id = client.instance_variable_get(:@raw_connection).object_id
    end

    # Travel past idle_timeout — connection is still valid, PING should succeed
    # and the same connection should be reused (no reconnect)
    travel(11) do
      pool.with do |client|
        client.call("PING")
        assert_equal raw_connection_id, client.instance_variable_get(:@raw_connection).object_id
      end
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

  def test_last_used_at_updated_after_each_command
    pool = RedisClient.config(**tcp_config).new_pool(size: 1, idle_timeout: 10)

    pool.with do |client|
      client.call("SET", "key", "value")
      first_used_at = client.last_used_at

      client.call("GET", "key")
      second_used_at = client.last_used_at

      assert_operator second_used_at, :>=, first_used_at
    end
  end

  def test_successive_commands_prevent_idle_timeout
    pool = RedisClient.config(**tcp_config).new_pool(size: 1, idle_timeout: 10)

    # First checkout: run a command so connection is established
    pool.call("PING")

    # Travel 6 seconds, run a command — this updates last_used_at
    travel(6) do
      pool.call("SET", "key", "value")
    end

    # Travel 6 more seconds (12 total since start, but only 6 since last command)
    # Should NOT trigger idle_timeout because last_used_at was refreshed
    travel(12) do
      assert_equal "value", pool.call("GET", "key")
    end
  end

  private

  def new_client(**overrides)
    RedisClient.config(**tcp_config.merge(overrides)).new_pool
  end
end
