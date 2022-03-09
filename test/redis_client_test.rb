# frozen_string_literal: true

require "test_helper"

class RedisClientTest < Minitest::Test
  def test_has_version
    assert_instance_of String, RedisClient::VERSION
  end
end
