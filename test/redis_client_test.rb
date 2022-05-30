# frozen_string_literal: true

require "test_helper"

class RedisClientTest < Minitest::Test
  include ClientTestHelper
  include RedisClientTests

  def test_preselect_database
    client = new_client(db: 5)
    assert_includes client.call("CLIENT", "INFO"), " db=5 "
    client.call("SELECT", 6)
    assert_includes client.call("CLIENT", "INFO"), " db=6 "
    client.close
    assert_includes client.call("CLIENT", "INFO"), " db=5 "
  end

  def test_set_client_id
    client = new_client(id: "peter")
    assert_includes client.call("CLIENT", "INFO"), " name=peter "
    client.call("CLIENT", "SETNAME", "steven")
    assert_includes client.call("CLIENT", "INFO"), " name=steven "
    client.close
    assert_includes client.call("CLIENT", "INFO"), " name=peter "
  end

  def test_encoding
    @redis.call("SET", "str", "fée")
    str = @redis.call("GET", "str")

    assert_equal Encoding.default_external, str.encoding
    assert_predicate str, :valid_encoding?

    bytes = "\xFF\00"
    refute_predicate bytes, :valid_encoding?

    @redis.call("SET", "str", bytes.b)
    str = @redis.call("GET", "str")

    assert_equal Encoding::BINARY, str.encoding
    assert_predicate str, :valid_encoding?
  end

  def test_dns_resolution_failure
    client = RedisClient.new(host: "does-not-exist.localhost")
    assert_raises RedisClient::ConnectionError do
      client.call("PING")
    end
  end

  def test_older_server
    fake_redis5_driver = Class.new(RedisClient::RubyConnection) do
      def call_pipelined(commands, *)
        if commands.any? { |c| c == ["HELLO", "3" ]}
          raise RedisClient::CommandError, "ERR unknown command `HELLO`, with args beginning with: `3`"
        else
          super
        end
      end
    end
    client = new_client(driver: fake_redis5_driver)

    error = assert_raises RedisClient::UnsupportedServer do
      client.call("PING")
    end
    assert_includes error.message, "Your Redis server version is too old"
  end
end
