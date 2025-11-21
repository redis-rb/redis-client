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
    end

    def teardown
      if @original_module
        RedisClient.send(:remove_const, :Middlewares)
        RedisClient.const_set(:Middlewares, @original_module)
      end
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

    def test_final_errors
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_equal("PONG", client.call("PING"))
      end

      calls = TestMiddleware.calls.select { |type, _| type == :call }
      assert_equal 2, calls.size

      call = calls[0]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      refute_predicate call[3], :final?

      call = calls[1]
      assert_equal :success, call[1]
      assert_equal ["PING"], call[2]

      TestMiddleware.calls.clear

      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING", "PING"]) do
        assert_raises ConnectionError do
          client.call("PING")
        end
      end

      calls = TestMiddleware.calls.select { |type, _| type == :call }
      assert_equal 2, calls.size

      call = calls[0]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      refute_predicate call[3], :final?

      call = calls[1]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      assert_predicate call[3], :final?

      TestMiddleware.calls.clear

      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_raises ConnectionError do
          client.call_once("PING")
        end
      end

      calls = TestMiddleware.calls.select { |type, _| type == :call }
      assert_equal 1, calls.size

      call = calls[0]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      assert_predicate call[3], :final?

      TestMiddleware.calls.clear
    end

    def test_final_errors_during_reconnect
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING", "HELLO"]) do
        assert_raises ConnectionError do
          client.call("PING")
        end
      end

      calls = TestMiddleware.calls.select { |type, _| type == :call }
      assert_equal 1, calls.size

      call = calls[0]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      refute_predicate call[3], :final?

      pipeline_calls = TestMiddleware.calls.select { |type, _| type == :pipeline }
      assert_equal 2, pipeline_calls.size

      failing_pipeline = pipeline_calls[1]
      assert_equal :error, failing_pipeline[1]
      assert_equal [["HELLO", "3"]], failing_pipeline[2]
      assert_predicate failing_pipeline[3], :final?
    end

    def test_command_error_final
      tcp_server = TCPServer.new("127.0.0.1", 0)
      tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      port = tcp_server.addr[1]

      server_thread = Thread.new do
        session = tcp_server.accept
        session.write("-Whoops\r\n")
        session.close
      end

      assert_raises CommandError do
        new_client(host: "127.0.0.1", port: port, reconnect_attempts: 1, protocol: 2).call("PING")
      end

      calls = TestMiddleware.calls.select { |type, _| type == :call }
      assert_equal 1, calls.size
      call = calls[0]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      assert_predicate call[3], :final?
    ensure
      server_thread&.kill
    end

    def test_protocol_error
      tcp_server = TCPServer.new("127.0.0.1", 0)
      tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      port = tcp_server.addr[1]

      server_thread = Thread.new do
        2.times do
          session = tcp_server.accept
          session.write("garbage\r\n")
          session.flush
          session.close
        end
      end

      assert_raises ProtocolError do
        new_client(host: "127.0.0.1", port: port, reconnect_attempts: 1, protocol: 2).call("PING")
      end

      calls = TestMiddleware.calls.select { |type, _| type == :call }
      assert_equal 2, calls.size

      call = calls[0]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      refute_predicate call[3], :final?

      call = calls[1]
      assert_equal :error, call[1]
      assert_equal ["PING"], call[2]
      assert_predicate call[3], :final?
    ensure
      server_thread&.kill
    end

    module DummyMiddleware
      def call(command, _config, &_)
        command
      end

      def call_pipelined(commands, _config, &_)
        commands
      end
    end

    module PreludeContextMiddleware
      class << self
        attr_accessor :contexts, :client
      end
      @contexts = []

      def initialize(client)
        super
        PreludeContextMiddleware.client = client
      end

      def call_pipelined(commands, config, context = nil, &block)
        PreludeContextMiddleware.contexts << context if context
        super
      end
    end

    def test_instance_middleware
      second_client = new_client(middlewares: [DummyMiddleware])
      assert_equal ["GET", "2"], second_client.call("GET", 2)
      assert_equal([["GET", "2"]], second_client.pipelined { |p| p.call("GET", 2) })
    end

    def test_prelude_context_is_exposed
      client = new_client(middlewares: [PreludeContextMiddleware])
      client.call("PING")

      context = PreludeContextMiddleware.contexts.find { |ctx| ctx && ctx[:stage] == :connection_prelude }
      refute_nil context
      assert_equal :connection_prelude, context[:stage]
      refute_nil context[:connection]
      assert_kind_of RedisClient, PreludeContextMiddleware.client
    ensure
      PreludeContextMiddleware.contexts.clear
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

      def connect(config)
        result = super
        TestMiddleware.calls << [:connect, :success, result, config]
        result
      rescue => error
        TestMiddleware.calls << [:connect, :error, error, config]
        raise
      end

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
