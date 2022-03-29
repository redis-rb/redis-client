# frozen_string_literal: true

require "benchmark"
require "test_helper"

class RedisClient
  module ConnectionTests
    def test_connection_working
      assert_equal "PONG", @redis.call("PING")
    end

    def test_connected?
      refute_predicate @redis, :connected?
      @redis.call("PING")
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

    private

    def assert_timeout(error, faster_than = 0.5, &block)
      realtime = Benchmark.realtime do
        assert_raises(error, &block)
      end

      assert realtime < faster_than, "Took longer than #{faster_than}s to timeout (#{realtime})"
    end
  end

  class TCPConnectionTest < Minitest::Test
    def setup
      @redis = new_client
    end

    include ConnectionTests

    private

    def new_client(**overrides)
      RedisClient.new(**RedisServerHelper.tcp_config.merge(overrides))
    end
  end

  class SSLConnectionTest < Minitest::Test
    def setup
      @redis = new_client
    end

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
    def setup
      @redis = new_client
    end

    def test_connection_working
      assert_equal "PONG", @redis.call("PING")
    end

    def new_client(**overrides)
      RedisClient.new(**RedisServerHelper.unix_config.merge(overrides))
    end
  end
end
