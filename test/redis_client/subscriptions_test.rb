# frozen_string_literal: true

require "test_helper"

class RedisClient
  class SubscriptionsTest < Minitest::Test
    def setup
      @redis = new_client
      @subscription = @redis.pubsub
    end

    def test_subscribe
      assert_nil @subscription.call("SUBSCRIBE", "mychannel")

      @redis.pipelined do |pipeline|
        3.times do |i|
          pipeline.call("PUBLISH", "mychannel", "event-#{i}")
        end
      end

      events = []
      while event = @subscription.next_event
        events << event
      end

      assert_equal [
        ["subscribe", "mychannel", 1],
        ["message", "mychannel", "event-0"],
        ["message", "mychannel", "event-1"],
        ["message", "mychannel", "event-2"],
      ], events
    end

    def test_psubscribe
      assert_nil @subscription.call("PSUBSCRIBE", "my*")

      @redis.pipelined do |pipeline|
        3.times do |i|
          pipeline.call("PUBLISH", "mychannel", "event-#{i}")
        end
      end

      events = []
      while event = @subscription.next_event
        events << event
      end

      assert_equal [
        ["psubscribe", "my*", 1],
        ["pmessage", "my*", "mychannel", "event-0"],
        ["pmessage", "my*", "mychannel", "event-1"],
        ["pmessage", "my*", "mychannel", "event-2"],
      ], events
    end

    def test_close
      assert_nil @subscription.call("SUBSCRIBE", "mychannel")
      @redis.pipelined do |pipeline|
        3.times do |i|
          pipeline.call("PUBLISH", "mychannel", "event-#{i}")
        end
      end

      assert_equal ["subscribe", "mychannel", 1], @subscription.next_event
      assert_equal @subscription, @subscription.close
      assert_raises ConnectionError do
        @subscription.next_event
      end
    end

    def test_next_event_timeout
      assert_nil @subscription.next_event(0.01)
    end

    private

    def new_client(**overrides)
      RedisClient.new(**RedisServerHelper.tcp_config.merge(overrides))
    end
  end
end
