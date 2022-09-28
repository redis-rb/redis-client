# frozen_string_literal: true

require "test_helper"

class RedisClient
  class MiddlewaresTest < Minitest::Test
    include ClientTestHelper

    def setup
      super
      @original_module = RedisClient::Middlewares
      new_module = @original_module.dup
      RedisClient.send(:remove_const, :Middlewares)
      RedisClient.const_set(:Middlewares, new_module)
      RedisClient.register(GlobalTestMiddleware)
      CallCollection.calls.clear
    end

    def teardown
      if @original_module
        RedisClient.send(:remove_const, :Middlewares)
        RedisClient.const_set(:Middlewares, @original_module)
      end
      CallCollection.calls.clear
      super
    end

    def redis_config
      super(middleware: LocalTestMiddleware1).tap do |config|
        config.register(LocalTestMiddleware2)
      end
    end

    def test_call_instrumentation
      @redis.call("PING")
      assert_calls [
        [:call, :success, ["PING"], "PONG", @redis.config, :local2],
        [:call, :success, ["PING"], "PONG", @redis.config, :local1],
        [:call, :success, ["PING"], "PONG", @redis.config, :global],
      ]
    end

    def test_failing_call_instrumentation
      assert_raises CommandError do
        @redis.call("PONG")
      end

      local_call2 = CallCollection.calls[0]
      assert_equal [:call, :error, ["PONG"]], local_call2.first(3)
      assert_instance_of CommandError, local_call2[3]

      local_call1 = CallCollection.calls[1]
      assert_equal [:call, :error, ["PONG"]], local_call1.first(3)
      assert_instance_of CommandError, local_call1[3]

      global_call = CallCollection.calls[2]
      assert_equal [:call, :error, ["PONG"]], global_call.first(3)
      assert_instance_of CommandError, global_call[3]
    end

    def test_call_once_instrumentation
      @redis.call_once("PING")
      assert_calls [
        [:call, :success, ["PING"], "PONG", @redis.config, :local2],
        [:call, :success, ["PING"], "PONG", @redis.config, :local1],
        [:call, :success, ["PING"], "PONG", @redis.config, :global],
      ]
    end

    def test_blocking_call_instrumentation
      @redis.blocking_call(nil, "PING")
      assert_calls [
        [:call, :success, ["PING"], "PONG", @redis.config, :local2],
        [:call, :success, ["PING"], "PONG", @redis.config, :local1],
        [:call, :success, ["PING"], "PONG", @redis.config, :global],
      ]
    end

    def test_pipeline_instrumentation
      @redis.pipelined do |pipeline|
        pipeline.call("PING")
      end
      assert_calls [
        [:pipeline, :success, [["PING"]], ["PONG"], @redis.config, :local2],
        [:pipeline, :success, [["PING"]], ["PONG"], @redis.config, :local1],
        [:pipeline, :success, [["PING"]], ["PONG"], @redis.config, :global],
      ]
    end

    def test_multi_instrumentation
      @redis.multi do |transaction|
        transaction.call("PING")
      end
      assert_calls [
        [:pipeline, :success, [["MULTI"], ["PING"], ["EXEC"]], ["OK", "QUEUED", ["PONG"]], @redis.config, :local2],
        [:pipeline, :success, [["MULTI"], ["PING"], ["EXEC"]], ["OK", "QUEUED", ["PONG"]], @redis.config, :local1],
        [:pipeline, :success, [["MULTI"], ["PING"], ["EXEC"]], ["OK", "QUEUED", ["PONG"]], @redis.config, :global],
      ]
    end

    private

    def assert_calls(calls)
      assert_equal calls, CallCollection.calls
    end

    module CallCollection
      class << self
        attr_accessor :calls
      end
      @calls = []
    end

    module BaseTestMiddleware
      def call(command, config)
        result = super
        CallCollection.calls << [:call, :success, command, result, config, middleware_class]
        result
      rescue => error
        CallCollection.calls << [:call, :error, command, error, config, middleware_class]
        raise
      end

      def call_pipelined(commands, config)
        result = super
        CallCollection.calls << [:pipeline, :success, commands, result, config, middleware_class]
        result
      rescue => error
        CallCollection.calls << [:pipeline, :error, commands, error, config, middleware_class]
        raise
      end
    end

    module GlobalTestMiddleware
      include BaseTestMiddleware

      def middleware_class
        :global
      end
    end

    module LocalTestMiddleware1
      include BaseTestMiddleware

      def middleware_class
        :local1
      end
    end

    module LocalTestMiddleware2
      include BaseTestMiddleware

      def middleware_class
        :local2
      end
    end
  end
end
