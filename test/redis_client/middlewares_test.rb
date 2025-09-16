# frozen_string_literal: true

require "test_helper"

class RedisClient
  class MiddlewaresTest < RedisClientTestCase
    include ClientTestHelper

    def setup
      @original_module = RedisClient::Middlewares
      new_module = @original_module.dup
      RedisClient.send(:remove_const, :Middlewares)
      RedisClient.const_set(:Middlewares, new_module)
      RedisClient.register(TestMiddleware)
      super
      TestMiddleware.calls.clear
      InstrumentRetryAttemptsMiddleware.calls.clear
    end

    def teardown
      if @original_module
        RedisClient.send(:remove_const, :Middlewares)
        RedisClient.const_set(:Middlewares, @original_module)
      end
      TestMiddleware.calls.clear
      InstrumentRetryAttemptsMiddleware.calls.clear
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

    module DummyMiddleware
      def call(command, _config, _retry_attempts = 0, &_)
        command
      end

      def call_pipelined(commands, _config, _retry_attempts = 0, &_)
        commands
      end
    end

    def test_instance_middleware
      second_client = new_client(middlewares: [DummyMiddleware])
      assert_equal ["GET", "2"], second_client.call("GET", 2)
      assert_equal([["GET", "2"]], second_client.pipelined { |p| p.call("GET", 2) })
    end

    def test_retry_instruments_attempts
      client = new_client(reconnect_attempts: 1, middlewares: [InstrumentRetryAttemptsMiddleware])

      simulate_network_errors(client, ["PING"]) do
        client.call("PING")
      end

      assert_includes InstrumentRetryAttemptsMiddleware.calls, [:call, :error, ["PING"], 0]
      assert_includes InstrumentRetryAttemptsMiddleware.calls, [:call, :success, ["PING"], 1]
    end

    def test_connect_instruments_attempts
      client = new_client(middlewares: [InstrumentRetryAttemptsMiddleware])

      client.call("PING")

      assert_includes InstrumentRetryAttemptsMiddleware.calls, [:connect, :success, 0]
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

      def connect(config, _retry_attempts = 0)
        result = super
        TestMiddleware.calls << [:connect, :success, result, config]
        result
      rescue => error
        TestMiddleware.calls << [:connect, :error, error, config]
        raise
      end

      def call(command, config, _retry_attempts = 0)
        result = super
        TestMiddleware.calls << [:call, :success, command, result, config]
        result
      rescue => error
        TestMiddleware.calls << [:call, :error, command, error, config]
        raise
      end

      def call_pipelined(commands, config, _retry_attempts = 0)
        result = super
        TestMiddleware.calls << [:pipeline, :success, commands, result, config]
        result
      rescue => error
        TestMiddleware.calls << [:pipeline, :error, commands, error, config]
        raise
      end
    end

    module InstrumentRetryAttemptsMiddleware
      class << self
        attr_accessor :calls
      end
      @calls = []

      def connect(config, retry_attempts = 0)
        result = super
        InstrumentRetryAttemptsMiddleware.calls << [:connect, :success, retry_attempts]
        result
      rescue
        InstrumentRetryAttemptsMiddleware.calls << [:connect, :error, retry_attempts]
        raise
      end

      def call(command, config, retry_attempts = 0)
        result = super
        InstrumentRetryAttemptsMiddleware.calls << [:call, :success, command, retry_attempts]
        result
      rescue
        InstrumentRetryAttemptsMiddleware.calls << [:call, :error, command, retry_attempts]
        raise
      end

      def call_pipelined(commands, config, retry_attempts = 0)
        result = super
        InstrumentRetryAttemptsMiddleware.calls << [:pipeline, :success, commands, retry_attempts]
        result
      rescue
        InstrumentRetryAttemptsMiddleware.calls << [:pipeline, :error, commands, retry_attempts]
        raise
      end
    end
  end
end
