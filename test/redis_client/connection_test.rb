# frozen_string_literal: true

require "benchmark"
require "test_helper"

class RedisClient
  module ConnectionTests
    def test_connection_working
      assert_equal "PONG", @redis.call("PING")
    end

    def test_connected?
      client = new_client
      refute_predicate client, :connected?

      client.call("PING")
      assert_predicate @redis, :connected?

      @redis.close
      refute_predicate @redis, :connected?

      @redis.call("PING")
      @redis.instance_variable_get(:@raw_connection).close
      refute_predicate @redis, :connected?
    end

    def test_connect_failure
      client = new_client(host: "example.com")
      assert_raises RedisClient::ConnectionError do
        client.call("PING")
      end
    end

    def test_redis_down_after_connect
      @redis.call("PING") # force connect
      Toxiproxy[/redis/].down do
        assert_raises RedisClient::ConnectionError do
          @redis.call("PING")
        end
      end
    end

    def test_redis_down_before_connect
      @redis.close
      Toxiproxy[/redis/].down do
        assert_raises RedisClient::ConnectionError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_connect_upstream_timeout
      @redis.close
      Toxiproxy[/redis/].upstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_connect_downstream_timeout
      @redis.close
      Toxiproxy[/redis/].upstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_upstream_timeout
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].upstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_upstream_latency
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].upstream(:latency, latency: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_downstream_timeout
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].downstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_downstream_latency
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].downstream(:latency, latency: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_reconnect_on_next_try
      value = "a" * 75
      @redis.call("SET", "foo", value)
      Toxiproxy[/redis/].downstream(:limit_data, bytes: 120).apply do
        assert_equal value, @redis.call("GET", "foo")
        assert_raises RedisClient::ConnectionError do
          @redis.call("GET", "foo")
        end
      end
      refute_predicate @redis, :connected?
      assert_equal value, @redis.call("GET", "foo")
    end

    def test_reconnect_attempts_disabled
      client = new_client(reconnect_attempts: false)
      simulate_network_errors(client, ["PING"]) do
        assert_raises ConnectionError do
          client.call("PING")
        end
      end
    end

    def test_reconnect_attempts_enabled
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_equal "PONG", client.call("PING")
      end
    end

    def test_reconnect_attempts_enabled_pipelines
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_equal(["PONG"], client.pipelined { |p| p.call("PING") })
      end
    end

    def test_reconnect_attempts_enabled_transactions
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_equal(["PONG"], client.multi { |p| p.call("PING") })
      end
    end

    def test_reconnect_attempts_enabled_watching_transactions
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_raises ConnectionError do
          client.multi(watch: ["foo"]) { |p| p.call("PING") }
        end
      end
    end

    def test_reconnect_attempts_enabled_inside_watching_transactions
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["GET"]) do
        assert_raises ConnectionError do
          client.multi(watch: ["foo"]) do |transaction|
            # Since we called WATCH, the connection becomes stateful, so we can't
            # simply reconnect on failure.
            assert_raises ConnectionError do
              client.call("GET", "foo")
            end
            transaction.call("SET", "foo", "2")
          end
        end
      end
    end

    def test_reconnect_with_non_idempotent_commands
      client = new_client(reconnect_attempts: 1)

      simulate_network_errors(client, ["INCR"]) do
        # The INCR command is retried, causing the counter to be incremented twice
        assert_equal 2, client.call("INCR", "counter")
      end
      assert_equal "2", client.call("GET", "counter")
    end

    def test_reconnect_with_call_once
      client = new_client(reconnect_attempts: 1)

      simulate_network_errors(client, ["INCR"]) do
        assert_raises ConnectionError do
          client.call_once("INCR", "counter")
        end
      end
      assert_equal "1", client.call("GET", "counter")
    end

    private

    def assert_timeout(error, faster_than = 0.5, &block)
      realtime = Benchmark.realtime do
        assert_raises(error, &block)
      end

      assert realtime < faster_than, "Took longer than #{faster_than}s to timeout (#{realtime})"
    end
  end

  class TCPConnectionTest < Minitest::Test
    include ClientTestHelper
    include ConnectionTests

    private

    def new_client(**overrides)
      RedisClient.new(**RedisServerHelper.tcp_config.merge(overrides))
    end
  end

  class SSLConnectionTest < Minitest::Test
    include ClientTestHelper
    include ConnectionTests

    if ENV["DRIVER"] == "hiredis"
      def test_tcp_connect_downstream_timeout
        skip "TODO: Find the proper way to timeout SSL connections with hiredis"
      end

      def test_tcp_connect_upstream_timeout
        skip "TODO: Find the proper way to timeout SSL connections with hiredis"
      end
    end

    private

    def new_client(**overrides)
      RedisClient.new(**RedisServerHelper.ssl_config.merge(overrides))
    end
  end

  class UnixConnectionTest < Minitest::Test
    include ClientTestHelper

    def test_connection_working
      assert_equal "PONG", @redis.call("PING")
    end

    private

    def new_client(**overrides)
      RedisClient.new(**RedisServerHelper.unix_config.merge(overrides))
    end
  end
end
