# frozen_string_literal: true

require "test_helper"

class RESP2ClientTest < Minitest::Test
  include ClientTestHelper

  def test_resp2_nil
    @redis.call("SET", "foo", "bar")
    assert_equal "bar", @redis.call("GETDEL", "foo")
    assert_nil @redis.call("GET", "foo")
  end

  def test_limited_type_casting
    assert_equal 1, @redis.call("INCR", "foo")
    @redis.call("HMSET", "hash", "foo", "bar")
    assert_equal ["foo", "bar"], @redis.call("HGETALL", "hash")
  end

  private

  def new_client(**overrides)
    RedisClient.config(**tcp_config, **overrides, protocol: 2).new_client
  end
end
