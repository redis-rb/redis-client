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
      RedisClient.register(TestMiddleware)
      TestMiddleware.calls.clear
    end

    def teardown
      RedisClient.send(:remove_const, :Middlewares)
      RedisClient.const_set(:Middlewares, @original_module)
      TestMiddleware.calls.clear
      super
    end

    def test_call_instrumentation
      @redis.call("PING")
      assert_call [:call, :success, ["PING"], "PONG", @redis.config]
    end

    def test_failing_call_instrumentation
      assert_raises CommandError do
        @redis.call("PONG")
      end
      call = TestMiddleware.calls.first
      assert_equal [:call, :error, ["PONG"]], call.first(3)
      assert_instance_of CommandError, call[3]
    end

    def test_call_once_instrumentation
      @redis.call_once("PING")
      assert_call [:call, :success, ["PING"], "PONG", @redis.config]
    end

    def test_blocking_call_instrumentation
      @redis.blocking_call(nil, "PING")
      assert_call [:call, :success, ["PING"], "PONG", @redis.config]
    end

    def test_pipeline_instrumentation
      @redis.pipelined do |pipeline|
        pipeline.call("PING")
      end
      assert_call [:pipeline, :success, [["PING"]], ["PONG"], @redis.config]
    end

    def test_multi_instrumentation
      @redis.multi do |transaction|
        transaction.call("PING")
      end
      assert_call [
        :pipeline,
        :success,
        [["MULTI"], ["PING"], ["EXEC"]],
        ["OK", "QUEUED", ["PONG"]],
        @redis.config,
      ]
    end

    private

    def assert_call(call)
      assert_equal call, TestMiddleware.calls.first
      assert_equal 1, TestMiddleware.calls.size
    end

    def assert_calls(calls)
      assert_equal calls, TestMiddleware.calls
    end

    module TestMiddleware
      class << self
        attr_accessor :calls
      end
      @calls = []

      def call(command, config)
        result = super
        TestMiddleware.calls << [:call, :success, command, result, config]
        result
      rescue => error
        TestMiddleware.calls << [:call, :error, command, error, config]
        raise
      end

      def call_pipelined(commands, config)
        result = super
        TestMiddleware.calls << [:pipeline, :success, commands, result, config]
        result
      rescue => error
        TestMiddleware.calls << [:pipeline, :error, commands, error, config]
        raise
      end
    end
  end
end
