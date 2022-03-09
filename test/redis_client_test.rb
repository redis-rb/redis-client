# frozen_string_literal: true

require "test_helper"

class RedisClientTest < Minitest::Test
  def setup
    @redis = RedisClient.new
  end

  def test_has_version
    assert_instance_of String, RedisClient::VERSION
  end

  def test_ping
    assert_equal "PONG", @redis.call("PING")
  end
end
