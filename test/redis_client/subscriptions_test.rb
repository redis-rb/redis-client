# frozen_string_literal: true

require "test_helper"

class RedisClient
  class SubscriptionsTest < RedisClientTestCase
    include ClientTestHelper

    def setup
      super
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

    def test_connection_lost
      assert_nil @subscription.call("SUBSCRIBE", "mychannel")
      @redis.call("PUBLISH", "mychannel", "event-0")
      assert_equal ["subscribe", "mychannel", 1], @subscription.next_event
      assert_equal ["message", "mychannel", "event-0"], @subscription.next_event

      assert_nil @subscription.next_event(0.2)
      assert_nil @subscription.next_event(0.2)
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

    def test_concurrent_use_while_connection_is_killed
      # Like redis-rb's SubscribedClient (used by ActionCable): one thread reads events
      # while other threads subscribe and unsubscribe, writes serialized by a lock.
      unexpected = Queue.new
      write_lock = Mutex.new
      kills = 0
      deadline = RedisClient.now + 2

      while RedisClient.now < deadline
        subscription = @redis.pubsub
        subscription.call("CLIENT", "ID")
        id = subscription.next_event
        stop = false
        threads = [Thread.new do
          subscription.next_event(0.01) until stop
        rescue ConnectionError
        rescue => error
          unexpected << error
        end]
        threads += 4.times.map do |i|
          Thread.new do
            until stop
              write_lock.synchronize { subscription.call("SUBSCRIBE", "channel-#{i}") }
              write_lock.synchronize { subscription.call("UNSUBSCRIBE", "channel-#{i}") }
            end
          rescue ConnectionError
          rescue => error
            unexpected << error
          end
        end

        sleep 0.01
        kills += @redis.call("CLIENT", "KILL", "ID", id) # only ours: other test workers share this server
        stop = true
        threads.each(&:join)
        subscription.close
      end

      assert_operator kills, :>, 0
      assert_equal [], Array.new(unexpected.size) { unexpected.pop }
    end

    def test_pubsub_with_disabled_reconnection
      @redis.send(:ensure_connected, retryable: false) do
        refute_nil @redis.pubsub
      end
    end

    def test_pubsub_timeout_retry
      assert_nil @subscription.call("SUBSCRIBE", "mychannel")
      refute_nil @subscription.next_event # subscribed event

      assert_nil @subscription.next_event(0.01)
      @redis.call("PUBLISH", "mychannel", "test")
      1.times.each do # rubocop:disable Lint/UselessTimes
        # We use 1.times.each to change the stack depth.
        # See https://github.com/redis-rb/redis-client/issues/221
        refute_nil @subscription.next_event
      end
    end
  end
end
