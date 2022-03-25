# frozen_string_literal: true

require "test_helper"

class RedisClient
  module ConnectionTests
    def test_connection_working
      assert_equal "PONG", @redis.call("PING")
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

    def test_tcp_upstream_timeout
      Toxiproxy[/redis/].upstream(:timeout, timeout: 3_000).apply do
        assert_raises RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_upstream_latency
      Toxiproxy[/redis/].upstream(:latency, latency: 3_000).apply do
        assert_raises RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_downstream_timeout
      Toxiproxy[/redis/].downstream(:timeout, timeout: 3_000).apply do
        assert_raises RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_downstream_latency
      Toxiproxy[/redis/].downstream(:latency, latency: 3_000).apply do
        assert_raises RedisClient::TimeoutError do
          p [:ping, @redis.call("PING")]
        end
      end
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
