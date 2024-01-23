# frozen_string_literal: true

require "test_helper"

class RactorTest < Minitest::Test
  def setup
    skip("Ractors are not supported on this Ruby version") unless defined?(::Ractor)
    skip("Hiredis is not Ractor safe") if RedisClient.default_driver.name == "RedisClient::HiredisConnection"
    begin
      Ractor.new { RedisClient.default_driver.name }.take
    rescue Ractor::RemoteError
      skip("Ractor implementation is too limited (MRI 3.0?)")
    end
  end

  def test_get_and_set_within_ractor
    ractor = Ractor.new do
      within_ractor_redis = ClientTestHelper.new_client
      within_ractor_redis.call("SET", "foo", "bar")
      within_ractor_redis.call("GET", "foo")
    end

    assert_equal("bar", ractor.take)
  end

  def test_multiple_ractors
    ractor1 = Ractor.new do
      within_ractor_redis = ClientTestHelper.new_client
      within_ractor_redis.call("SET", "foo", "bar")
      within_ractor_redis.call("GET", "foo")
    end

    ractor1.take # We do this to ensure that the SET has been processed

    ractor2 = Ractor.new do
      key = Ractor.receive
      within_ractor_redis = ClientTestHelper.new_client
      within_ractor_redis.call("GET", key)
    end
    ractor2.send("foo")

    assert_equal("bar", ractor2.take)
  end
end
