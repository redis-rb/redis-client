# frozen_string_literal: true

require "test_helper"

class RedisClient
  class SentinelTest < RedisClientTestCase
    include ClientTestHelper

    def setup
      @config = new_config
      super
      @config = new_config
    end

    def check_server
      retried = false
      begin
        @redis = @config.new_client
        @redis.call("FLUSHDB")
      rescue
        if retried
          raise
        else
          retried = true
          Servers::SENTINEL_TESTS.reset
          retry
        end
      end
    end

    def teardown
      Servers::SENTINEL_TESTS.reset
      super
    end

    def test_new_client
      assert_equal "PONG", @config.new_client.call("PING")
    end

    def test_url_list
      sentinel_config = new_config(sentinels: Servers::SENTINELS.map { |s| "redis://#{s.host}:#{s.port}" })
      assert_equal "PONG", sentinel_config.new_client.call("PING")
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
      attr_reader :close_count

      def initialize(responses)
        @responses = responses
        @close_count = 0
      end

      def call(*args)
        command, response = @responses.shift
        if command == args
          if block_given?
            yield response
          else
            response
          end
        else
          raise "Expected #{command.inspect}, got: #{args.inspect}"
        end
      end

      def close
        @close_count += 1
      end
    end

    def test_unknown_master
      @config = new_config(name: "does-not-exist")
      client = @config.new_client
      assert_raises ConnectionError do
        client.call("PING")
      end
    end

    def test_unresolved_config
      client = @config.new_client

      stub(@config, :server_url, -> { raise ConnectionError.with_config('this should not be called', @config) }) do
        stub(@config, :resolved?, false) do
          stub(client, :call, ->(_) { raise ConnectionError.with_config('call error', @config) }) do
            error = assert_raises ConnectionError do
              client.call('PING')
            end

            assert_equal 'call error', error.message
          end
        end
      end
    end

    def test_master_failover_not_ready
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
        sentinel_refresh_command_mock,
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
        sentinel_refresh_command_mock,
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
        sentinel_refresh_command_mock,
      ])
      stub(@config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_raises FailoverError do
          client.call("PING")
        end
      end
    end

    def test_master_failover_ready
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS.host, Servers::REDIS.port.to_s]],
        sentinel_refresh_command_mock,
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS_REPLICA.host, Servers::REDIS_REPLICA.port.to_s]],
        sentinel_refresh_command_mock,
      ])
      replica = RedisClient.new(host: Servers::REDIS_REPLICA.host, port: Servers::REDIS_REPLICA.port)
      assert_equal "OK", replica.call("REPLICAOF", "NO", "ONE")

      stub(@config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_equal "PONG", client.call("PING")
        initial_server_key = @config.server_key

        Toxiproxy[Servers::REDIS.name].down do
          assert_equal "PONG", client.call("PING")
          refute_equal initial_server_key, @config.server_key
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
      stub(@config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        assert_raises ConnectionError do
          @config.new_client.call("PING")
        end
      end
    end

    def test_replica_failover_not_ready
      @config = new_config(role: :replica)
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "replicas", "cache"], [response_hash("ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave")]],
        [["SENTINEL", "replicas", "cache"], [response_hash("ip" => Servers::REDIS.host, "port" => Servers::REDIS.port.to_s, "flags" => "slave")]],
        [["SENTINEL", "replicas", "cache"], [response_hash("ip" => Servers::REDIS.host, "port" => Servers::REDIS.port.to_s, "flags" => "slave")]],
      ])
      stub(@config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
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
        [["SENTINEL", "replicas", "cache"], [response_hash("ip" => Servers::REDIS.host, "port" => Servers::REDIS.port.to_s, "flags" => "slave")]],
        [["SENTINEL", "replicas", "cache"], [response_hash("ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave")]],
        [["SENTINEL", "replicas", "cache"], [response_hash("ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave")]],
        [["SENTINEL", "replicas", "cache"], [response_hash("ip" => Servers::REDIS_REPLICA.host, "port" => Servers::REDIS_REPLICA.port.to_s, "flags" => "slave")]],
      ])

      stub(@config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_equal "PONG", client.call("PING")
      end
    end

    def test_successful_connection_refreshes_sentinels_list
      assert_equal Servers::SENTINELS.length, @config.sentinels.length

      new_sentinel_ip = "10.0.0.1"
      new_sentinel_port = 1234

      # Trigger sentinel refresh to make the client aware of a new sentinel
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS.host, Servers::REDIS.port.to_s]],
        sentinel_refresh_command_mock(
          additional_sentinels: [response_hash("ip" => new_sentinel_ip, "port" => new_sentinel_port.to_s)],
        ),
      ])
      stub(@config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_equal "PONG", client.call("PING")
      end

      assert_equal Servers::SENTINELS.length + 1, @config.sentinels.length
      assert_equal new_sentinel_ip, @config.sentinels.last.host
      assert_equal new_sentinel_port, @config.sentinels.last.port
      assert_equal 1, sentinel_client_mock.close_count
    end

    def test_sentinel_refresh_password
      @config = new_config(sentinel_password: "hunter2")

      assert_equal Servers::SENTINELS.length, @config.sentinels.length

      new_sentinel_ip = "10.0.0.1"
      new_sentinel_port = 1234

      # Trigger sentinel refresh to make the client aware of a new sentinel
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS.host, Servers::REDIS.port.to_s]],
        sentinel_refresh_command_mock(
          additional_sentinels: [response_hash("ip" => new_sentinel_ip, "port" => new_sentinel_port.to_s)],
        ),
      ])

      stub(@config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        client = @config.new_client
        assert_equal "PONG", client.call("PING")
      end

      assert_equal Servers::SENTINELS.length + 1, @config.sentinels.length
      @config.sentinels.each do |sentinel|
        refute_nil sentinel.password
      end

      assert_equal 1, sentinel_client_mock.close_count
    end

    def test_hide_sentinel_password
      config = new_config(sentinel_password: "PASSWORD")
      refute_match "PASSWORD", config.inspect
      refute_match "PASSWORD", config.to_s
    end

    def test_config_user_password_from_url_for_redis_master_replica_only
      config = new_config(url: "redis://george:hunter2@cache/10", name: nil)
      assert_equal "hunter2", config.password
      assert_equal "george", config.username
      assert_equal 10, config.db
      assert_equal [Servers::REDIS.host, Servers::REDIS.port], [config.host, config.port]

      config.sentinels.each do |sentinel|
        assert_nil sentinel.password
      end
    end

    def test_config_ssl_from_rediss_url
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS.host, Servers::REDIS.port.to_s]],
        sentinel_refresh_command_mock,
      ])

      config = new_config(url: "rediss://george:hunter2@cache/10", name: nil)

      stub(config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        assert_equal "hunter2", config.password
        assert_equal "george", config.username
        assert_equal 10, config.db
        assert_predicate config, :ssl?
        assert_equal [Servers::REDIS.host, Servers::REDIS.port], [config.host, config.port]

        config.sentinels.each do |sentinel|
          assert_nil sentinel.password
          refute_predicate sentinel, :ssl?
        end
      end
    end

    def test_explicit_ssl_option_overrides_url
      sentinel_client_mock = SentinelClientMock.new([
        [["SENTINEL", "get-master-addr-by-name", "cache"], [Servers::REDIS.host, Servers::REDIS.port.to_s]],
        sentinel_refresh_command_mock,
      ])

      # Passing ssl: true should enable SSL for both Redis and Sentinel configs
      config = new_config(ssl: true)

      stub(config, :sentinel_client, ->(_config) { sentinel_client_mock }) do
        assert_predicate config, :ssl?, "Expected Redis config to use SSL when explicitly passed"

        config.sentinels.each do |sentinel|
          assert_predicate sentinel, :ssl?, "Expected Sentinel config to use SSL when explicitly passed"
        end
      end
    end

    def test_sentinel_shared_username_password
      config = new_config(sentinel_username: "alice", sentinel_password: "superpassword")

      config.sentinels.each do |sentinel|
        assert_equal "alice", sentinel.username
        assert_equal "superpassword", sentinel.password
      end
    end

    def test_sentinel_explicit_username_password
      sentinels = Servers::SENTINELS.map do |sentinel|
        { host: sentinel.host, port: sentinel.port, username: "alice", password: "superpassword" }
      end

      config = new_config(sentinels: sentinels)
      config.sentinels.each do |sentinel|
        assert_equal "alice", sentinel.username
        assert_equal "superpassword", sentinel.password
      end
    end

    def test_sentinel_config_from_url
      sentinels = Servers::SENTINELS.map do |sentinel|
        "redis://alice:superpassword@#{sentinel.host}:#{sentinel.port}"
      end

      config = new_config(sentinels: sentinels)
      assert_equal Servers::SENTINELS.length, config.sentinels.length
      config.sentinels.each do |sentinel|
        assert_equal "alice", sentinel.username
        assert_equal "superpassword", sentinel.password
      end
    end

    private

    def response_hash(hash)
      hash
    end

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

    def sentinel_refresh_command_mock(additional_sentinels: [])
      sentinels = Servers::SENTINELS.map do |sentinel|
        response_hash("ip" => sentinel.host, "port" => sentinel.port.to_s)
      end

      [["SENTINEL", "sentinels", "cache"], sentinels.concat(additional_sentinels)]
    end
  end

  class RESP2SentinelTest < SentinelTest
    def test_sentinel_refresh_password
      skip("On RESP2, AUTH require the redis server to have a default password")
    end

    private

    def new_config(**kwargs)
      super(**kwargs, protocol: 2)
    end

    def response_hash(hash)
      # In RESP2 hashes are returned as flat arrays
      hash.to_a.flatten(1)
    end
  end
end
