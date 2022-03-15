# frozen_string_literal: true

require "test_helper"

class RedisClientTest < Minitest::Test
  def setup
    @redis = new_client
    @redis.call("FLUSHDB")
  end

  def test_has_version
    assert_instance_of String, RedisClient::VERSION
  end

  def test_ping
    assert_equal "PONG", @redis.call("PING")
  end

  def test_get_set
    string = "a" * 15_000
    assert_equal "OK", @redis.call("SET", "foo", string)
    assert_equal string, @redis.call("GET", "foo")
  end

  def test_hashes
    @redis.call("HMSET", "foo", "bar", "1", "baz", "2")
    assert_equal({ "bar" => "1", "baz" => "2" }, @redis.call("HGETALL", "foo"))
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

  def test_authentication
    @redis.call("ACL", "SETUSER", "AzureDiamond", ">hunter2", "on", "+PING")

    client = new_client(username: "AzureDiamond", password: "hunter2")
    assert_equal "PONG", client.call("PING")

    assert_raises RedisClient::PermissionError do
      client.call("GET", "foo")
    end

    client = new_client(username: "AzureDiamond", password: "trolilol")
    assert_raises RedisClient::AuthenticationError do
      client.call("PING")
    end
  end

  private

  def new_client(**overrides)
    RedisClient.new(**RedisServerHelper.tcp_config.merge(overrides))
  end
end
