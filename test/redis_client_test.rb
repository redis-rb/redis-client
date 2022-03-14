# frozen_string_literal: true

require "test_helper"

class RedisClientTest < Minitest::Test
  def setup
    @redis = new_client
  end

  def test_has_version
    assert_instance_of String, RedisClient::VERSION
  end

  def test_ping
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
      assert_raises RedisClient::ReadTimeoutError do
        @redis.call("PING")
      end
    end
  end

  def test_tcp_upstream_latency
    Toxiproxy[/redis/].upstream(:latency, latency: 3_000).apply do
      assert_raises RedisClient::ReadTimeoutError do
        @redis.call("PING")
      end
    end
  end

  def test_tcp_downstream_timeout
    Toxiproxy[/redis/].downstream(:timeout, timeout: 3_000).apply do
      assert_raises RedisClient::ReadTimeoutError do
        @redis.call("PING")
      end
    end
  end

  def test_tcp_downstream_latency
    Toxiproxy[/redis/].downstream(:latency, latency: 3_000).apply do
      assert_raises RedisClient::ReadTimeoutError do
        @redis.call("PING")
      end
    end
  end

  def test_get_set
    string = "a" * 15_000
    assert_equal "OK", @redis.call("SET", "foo", string)
    assert_equal string, @redis.call("GET", "foo")
  end

  def test_pipelining
    result = @redis.pipelined do |pipeline|
      assert_nil pipeline.call("SET", "foo", "42")
      assert_equal "OK", @redis.call("SET", "foo", "21") # Not pipelined
      assert_nil pipeline.call("EXPIRE", "foo", "100")
    end
    assert_equal ["OK", 1], result
  end

  def test_pipelining_error
    assert_raises RedisClient::CommandError do
      @redis.pipelined do |pipeline|
        pipeline.call("DOESNOTEXIST")
        pipeline.call("SET", "foo", "42")
      end
    end

    assert_equal "42", @redis.call("GET", "foo")
  end

  def test_command_missing
    error = assert_raises RedisClient::CommandError do
      @redis.call("DOESNOTEXIST", "foo")
    end
    assert error.message.start_with?("ERR unknown command `DOESNOTEXIST`")
  end

  private

  def new_client(**overrides)
    RedisClient.new(**RedisServerHelper.tcp_config.merge(overrides))
  end
end
