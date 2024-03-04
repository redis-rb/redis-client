# frozen_string_literal: true

require "benchmark"
require "test_helper"

class RedisClient
  module ConnectionTests
    def test_connection_working
      assert_equal "PONG", @redis.call("PING")
    end

    def test_connected?
      client = new_client
      refute_predicate client, :connected?

      client.call("PING")
      assert_predicate @redis, :connected?

      @redis.close
      refute_predicate @redis, :connected?

      @redis.call("PING")
      @redis.instance_variable_get(:@raw_connection).close
      refute_predicate @redis, :connected?
    end

    def test_connect_failure
      client = new_client(host: "example.com")
      error = assert_raises RedisClient::ConnectionError do
        client.call("PING")
      end

      assert_match(%r{ \(rediss?://example.com:.*\)$}, error.message)
    end

    def test_redis_down_after_connect
      @redis.call("PING") # force connect
      Toxiproxy[/redis/].down do
        error = assert_raises RedisClient::ConnectionError do
          @redis.call("PING")
        end

        assert_match(%r{ \(rediss?://127.0.0.1:.*\)$}, error.message)
      end
    end

    def test_redis_down_before_connect
      @redis.close
      Toxiproxy[/redis/].down do
        error = assert_raises RedisClient::ConnectionError do
          @redis.call("PING")
        end

        assert_match(%r{ \(rediss?://127.0.0.1:.*\)$}, error.message)
      end
    end

    def test_tcp_connect_upstream_timeout
      @redis.close
      Toxiproxy[/redis/].upstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::ConnectionError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_connect_downstream_timeout
      @redis.close
      Toxiproxy[/redis/].upstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::ConnectionError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_upstream_timeout
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].upstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_upstream_latency
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].upstream(:latency, latency: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_downstream_timeout
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].downstream(:timeout, timeout: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_tcp_downstream_latency
      @redis.call("PING") # pre-connect
      Toxiproxy[/redis/].downstream(:latency, latency: 2_000).apply do
        assert_timeout RedisClient::TimeoutError do
          @redis.call("PING")
        end
      end
    end

    def test_reconnect_on_next_try
      value = "a" * 75
      @redis.call("SET", "foo", value)
      Toxiproxy[/redis/].downstream(:limit_data, bytes: 120).apply do
        assert_equal value, @redis.call("GET", "foo")
        assert_raises RedisClient::ConnectionError do
          @redis.call("GET", "foo")
        end
      end
      refute_predicate @redis, :connected?
      assert_equal value, @redis.call("GET", "foo")
    end

    def test_reconnect_attempts_disabled
      client = new_client(reconnect_attempts: false)
      simulate_network_errors(client, ["PING"]) do
        assert_raises ConnectionError do
          client.call("PING")
        end
      end
    end

    def test_reconnect_attempts_enabled
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_equal "PONG", client.call("PING")
      end
    end

    def test_reconnect_attempts_enabled_pipelines
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_equal(["PONG"], client.pipelined { |p| p.call("PING") })
      end
    end

    def test_reconnect_attempts_enabled_transactions
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_equal(["PONG"], client.multi { |p| p.call("PING") })
      end
    end

    def test_reconnect_attempts_enabled_watching_transactions
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["PING"]) do
        assert_raises ConnectionError do
          client.multi(watch: ["foo"]) { |p| p.call("PING") }
        end
      end
    end

    def test_reconnect_attempts_enabled_inside_watching_transactions
      client = new_client(reconnect_attempts: 1)
      simulate_network_errors(client, ["GET"]) do
        assert_raises ConnectionError do
          client.multi(watch: ["foo"]) do |transaction|
            # Since we called WATCH, the connection becomes stateful, so we can't
            # simply reconnect on failure.
            assert_raises ConnectionError do
              client.call("GET", "foo")
            end
            transaction.call("SET", "foo", "2")
          end
        end
      end
    end

    def test_reconnect_with_non_idempotent_commands
      client = new_client(reconnect_attempts: 1)

      simulate_network_errors(client, ["INCR"]) do
        # The INCR command is retried, causing the counter to be incremented twice
        assert_equal 2, client.call("INCR", "counter")
      end
      assert_equal "2", client.call("GET", "counter")
    end

    def test_reconnect_with_call_once
      client = new_client(reconnect_attempts: 1)

      simulate_network_errors(client, ["INCR"]) do
        assert_raises ConnectionError do
          client.call_once("INCR", "counter")
        end
      end
      assert_equal "1", client.call("GET", "counter")
    end

    def test_reconnect_reuse
      5.times do
        @redis.close
        assert_equal "PONG", @redis.call("PING")
      end
    end

    def test_circuit_breaker
      circuit_breaker = CircuitBreaker.new(error_threshold: 3, success_threshold: 2, error_timeout: 1)
      @redis = new_client(circuit_breaker: circuit_breaker)

      assert_equal "PONG", @redis.call("PING")
      Toxiproxy[/redis/].down do
        circuit_breaker.error_threshold.times do
          assert_raises ConnectionError do
            @redis.call("PING")
          end
        end
      end

      assert_equal "PONG", new_client.call("PING")

      assert_raises CircuitBreaker::OpenCircuitError do
        @redis.call("PING")
      end

      assert_raises CircuitBreaker::OpenCircuitError do
        @redis.config.new_client.call("PING")
      end

      travel(circuit_breaker.error_timeout) do
        assert_equal "PONG", @redis.call("PING")
      end
    end

    def test_circuit_breaker_initial_connection_exception
      circuit_breaker = CircuitBreaker.new(error_threshold: 1, success_threshold: 1, error_timeout: 1)
      @redis = new_client(circuit_breaker: circuit_breaker, reconnect_attempts: 2)

      Toxiproxy[/redis/].down do
        error = assert_raises CannotConnectError do
          @redis.call("PING")
        end
        refute_instance_of CircuitBreaker::OpenCircuitError, error
      end
    end

    def test_killed_connection
      client = new_client(reconnect_attempts: 1, id: "background")

      thread = Thread.new do
        client.blocking_call(false, "BLPOP", "list", 0)
      end
      thread.join(0.1)
      assert_predicate thread, :alive?

      second_client = new_client

      id = second_client.call("CLIENT", "LIST").lines.grep(/name=background/)[0].match(/^id=(\d+)/)[1]
      assert_equal 1, second_client.call("CLIENT", "KILL", "ID", id)
      second_client.call("LPUSH", "list", "hello")
      assert_equal ["list", "hello"], thread.join.value
    end

    def test_oom_errors
      config_client = new_client
      old_max_memory = config_client.call("config", "get", "maxmemory").fetch("maxmemory")
      begin
        config_client.call("config", "set", "maxmemory", "1") # 1 byte
        client = new_client
        assert_raises RedisClient::OutOfMemoryError do
          client.call("SET", "foo", "a" * 1000)
        end

        assert_raises RedisClient::OutOfMemoryError do
          client.call("EVAL", "redis.call('SET', 'foo', '#{'a' * 1000}')", 0)
        end
      ensure
        config_client.call("config", "set", "maxmemory", old_max_memory)
      end
    end

    private

    def assert_timeout(error, faster_than = 0.5, &block)
      realtime = Benchmark.realtime do
        assert_raises(error, &block)
      end

      assert realtime < faster_than, "Took longer than #{faster_than}s to timeout (#{realtime})"
    end
  end

  class TCPConnectionTest < Minitest::Test
    include ClientTestHelper
    include ConnectionTests

    def test_connecting_to_a_ssl_server
      client = new_client(**ssl_config, ssl: false)
      error = assert_raises CannotConnectError do
        client.call("PING")
      end

      assert_match(%r{ \(rediss?://.*:.*\)$}, error.message)
    end

    def test_protocol_error
      tcp_server = TCPServer.new("127.0.0.1", 0)
      tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      port = tcp_server.addr[1]

      server_thread = Thread.new do
        session = tcp_server.accept
        session.write("invalid")
        session.close
      end

      error = assert_raises RedisClient::ProtocolError do
        new_client(host: "127.0.0.1", port: port).call("PING")
      end

      assert_match(%r{ \(rediss?://127.0.0.1:#{port}\)$}, error.message)
    ensure
      server_thread&.kill
    end

    def test_boolean_replies
      # The RESP3 protocol allows for boolean replies, but I'm not aware of
      # any commands doing so. So to test for potential future commands returning
      # a boolean, we use a fake server.

      tcp_server = TCPServer.new("127.0.0.1", 0)
      tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      port = tcp_server.addr[1]

      server_thread = Thread.new do
        session = tcp_server.accept
        io = RubyConnection::BufferedIO.new(session, read_timeout: 1, write_timeout: 1)
        while command = RESP3.load(io)
          case command.first
          when "HELLO"
            session.write("_\r\n")
          when "ECHO"
            session.write(command[1])
          else
            session.write("-ERR Unknown command #{command.first}\r\n")
          end
        end
        session.close
      end

      client = new_client(host: "127.0.0.1", port: port)
      assert_equal true, client.call("ECHO", "#t\r\n")
      assert_equal false, client.call("ECHO", "#f\r\n")
      assert_nil client.call("ECHO", "_\r\n")
    ensure
      server_thread&.kill
    end

    def test_reconnect_on_readonly
      tcp_server = TCPServer.new("127.0.0.1", 0)
      tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      port = tcp_server.addr[1]

      server_thread = Thread.new do
        session = tcp_server.accept
        io = RubyConnection::BufferedIO.new(session, read_timeout: 1, write_timeout: 1)
        while command = RESP3.load(io)
          case command.first
          when "HELLO"
            session.write("_\r\n")
          when "PING"
            session.write("+PING\r\n")
          when "SET"
            session.write("-READONLY You can't write against a read only replica.\r\n")
          else
            session.write("-ERR Unknown command #{command.first}\r\n")
          end
        end
        session.close
      end

      client = new_client(host: "127.0.0.1", port: port)
      client.call("PING")
      error = assert_raises RedisClient::ReadOnlyError do
        client.call("SET", "foo", "bar")
      end
      refute_predicate client, :connected?
      assert_match(%r{ \(rediss?://127.0.0.1:#{port}\)$}, error.message)
    ensure
      server_thread&.kill
    end

    def test_reconnect_on_masterdown
      tcp_server = TCPServer.new("127.0.0.1", 0)
      tcp_server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      port = tcp_server.addr[1]

      server_thread = Thread.new do
        session = tcp_server.accept
        io = RubyConnection::BufferedIO.new(session, read_timeout: 1, write_timeout: 1)
        while command = RESP3.load(io)
          case command.first
          when "HELLO"
            session.write("_\r\n")
          when "PING"
            session.write("+PING\r\n")
          when "SET"
            session.write("-MASTERDOWN Link with MASTER is down and replica-serve-stale-data is set to 'no'\r\n")
          else
            session.write("-ERR Unknown command #{command.first}\r\n")
          end
        end
        session.close
      end

      client = new_client(host: "127.0.0.1", port: port)
      client.call("PING")
      assert_raises RedisClient::MasterDownError do
        client.call("SET", "foo", "bar")
      end
      refute_predicate client, :connected?
    ensure
      server_thread&.kill
    end

    private

    def new_client(**overrides)
      RedisClient.new(**tcp_config, **overrides)
    end
  end

  class SSLConnectionTest < Minitest::Test
    include ClientTestHelper
    include ConnectionTests

    def test_connecting_to_a_raw_tcp_server
      client = new_client(**tcp_config, ssl: true)
      assert_raises CannotConnectError do
        client.call("PING")
      end
    end

    private

    def new_client(**overrides)
      RedisClient.new(**ssl_config, **overrides)
    end
  end

  class UnixConnectionTest < Minitest::Test
    include ClientTestHelper

    def test_connection_working
      assert_equal "PONG", @redis.call("PING")
    end

    def test_missing_socket
      assert_raises RedisClient::CannotConnectError do
        new_client(path: "/tmp/does-not-exist").call("PING")
      end
    end

    private

    def new_client(**overrides)
      RedisClient.new(**unix_config, **overrides)
    end
  end
end
