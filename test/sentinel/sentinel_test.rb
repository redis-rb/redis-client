# frozen_string_literal: true

require "test_helper"

class RedisClient
  class SentinelTest < Minitest::Test
    include ClientTestHelper

    def setup
      super
      @config = new_config
    end

    def teardown
      Servers::SENTINEL_TESTS.reset
    end

    def test_new_client
      assert_equal "PONG", @config.new_client.call("PING")
    end

    def test_sentinel_config
      assert_equal [Servers::REDIS.host, Servers::REDIS.port], [@config.host, @config.port]
    end

    def test_sentinel_down
      assert_equal [Servers::REDIS.host, Servers::REDIS.port], [@config.host, @config.port]

      original_order = Servers::SENTINELS.map(&:port)
      assert_equal original_order, @config.sentinels.map(&:port)
      Toxiproxy[/sentinel_(1|3)/].down do
        @config.reset
        assert_equal [Servers::REDIS.host, Servers::REDIS.port], [@config.host, @config.port]
        expected_order = [Servers::SENTINELS[1].port, Servers::SENTINELS[0].port, Servers::SENTINELS[2].port]
        assert_equal expected_order, @config.sentinels.map(&:port)
      end
    end

    def test_sentinel_all_down
      Toxiproxy[/sentinel_.*/].down do
        assert_raises RedisClient::ConnectionError do
          @config.new_client.call("PING")
        end
      end
    end

    class SentinelClientMock
      def initialize(responses)
        @responses = responses
      end

      def call(*args)
        command, response = @responses.shift
        if command == args
          response
        else
          raise "Expected #{command.inspect}, got: #{args.inspect}"
        end
      end
    end

    def test_unknown_master
      @config = new_config(name: "does-not-exist")
      client = @config.new_client
      assert_raises ConnectionError do
        client.call("PING")
      end
    end

    def test_master_failover_not_ready
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
      ])
      @config.stub(:sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_raises FailoverError do
          client.call("PING")
        end
      end
    end

    def test_master_failover_ready
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS.host, Servers::REDIS.port.to_s]],
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
      ])
      replica = RedisClient.new(host: Servers::REDIS_REPLICA.host, port: Servers::REDIS_REPLICA.port)
      assert_equal "OK", replica.call("REPLICAOF", "NO", "ONE")

      @config.stub(:sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_equal "PONG", client.call("PING")

        Toxiproxy[Servers::REDIS.name].down do
          assert_equal "PONG", client.call("PING")
        end
      end
    ensure
      replica = RedisClient.new(host: Servers::REDIS_REPLICA.host, port: Servers::REDIS_REPLICA.port)
      assert_equal "OK", replica.call("REPLICAOF", Servers::REDIS.host, Servers::REDIS.port)
    end

    def test_no_replicas
      @config = new_config(role: :replica)
      tries = Servers::SENTINELS.size * (SentinelConfig::DEFAULT_RECONNECT_ATTEMPTS + 1)
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "replicas", "cache"], []],
      ] * tries)
      @config.stub(:sentinel_client, ->(_config) { sentinel_client_mock }) do
        assert_raises ConnectionError do
          @config.new_client.call("PING")
        end
      end
    end

    def test_replica_failover_not_ready
      @config = new_config(role: :replica)
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "replicas", "cache"], [{ "ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave" }]],
        [["SENTINEL", "replicas", "cache"], [{ "ip" => Servers::REDIS.host, "port" => Servers::REDIS.port.to_s, "flags" => "slave" }]],
        [["SENTINEL", "replicas", "cache"], [{ "ip" => Servers::REDIS.host, "port" => Servers::REDIS.port.to_s, "flags" => "slave" }]],
      ])
      @config.stub(:sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_equal "PONG", client.call("PING")

        Toxiproxy[Servers::REDIS_REPLICA.name].down do
          assert_raises FailoverError do
            client.call("PING")
          end
        end
      end
    end

    def test_replica_failover_ready
      @config = new_config(role: :replica)
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "replicas", "cache"], [{ "ip" => Servers::REDIS.host, "port" => Servers::REDIS.port.to_s, "flags" => "slave" }]],
        [["SENTINEL", "replicas", "cache"], [{ "ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave" }]],
        [["SENTINEL", "replicas", "cache"], [{ "ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave" }]],
        [["SENTINEL", "replicas", "cache"], [{ "ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave" }]],
      ])

      @config.stub(:sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_equal "PONG", client.call("PING")
      end
    end

    private

    def new_config(**kwargs)
      RedisClient.sentinel(
        name: Servers::SENTINEL_NAME,
        sentinels: Servers::SENTINELS.map do |sentinel|
          { host: sentinel.host, port: sentinel.port }
        end,
        timeout: 0.1,
        driver: ENV.fetch("DRIVER", "ruby").to_sym,
        **kwargs,
      )
    end
  end
end
