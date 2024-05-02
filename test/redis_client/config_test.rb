# frozen_string_literal: true

require "test_helper"

class RedisClient
  class ConfigTest < Minitest::Test
    def test_simple_uri
      config = Config.new(url: "redis://example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_nil config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
    end

    def test_unix_uri
      config = Config.new(url: "/run/redis/test.sock?db=1")
      assert_equal "/run/redis/test.sock", config.path
      assert_nil config.host
      assert_nil config.port
      assert_equal 1, config.db

      config = Config.new(url: "run/redis/test.sock?db=1")
      assert_equal "run/redis/test.sock", config.path
      assert_nil config.host
      assert_nil config.port
      assert_equal 1, config.db

      config = Config.new(url: "unix:///run/redis/test.sock?db=1")
      assert_equal "/run/redis/test.sock", config.path
      assert_nil config.host
      assert_nil config.port
      assert_equal 1, config.db

      config = Config.new(url: "unix://run/redis/test.sock?db=1")
      assert_equal "run/redis/test.sock", config.path
      assert_nil config.host
      assert_nil config.port
      assert_equal 1, config.db
    end

    def test_uri_instance
      config = Config.new(url: URI.parse("redis://example.com"))
      assert_equal "example.com", config.host
    end

    def test_invalid_url
      error = assert_raises ArgumentError do
        Config.new(url: "http://example.com")
      end
      assert_includes error.message, "Unknown URL scheme"
      assert_includes error.message, "example.com"
    end

    def test_defaults_to_localhost
      config = Config.new(url: "redis://")

      assert_equal "localhost", config.host
    end

    def test_ipv6_uri
      config = Config.new(url: "redis://[::1]")
      assert_equal "::1", config.host
    end

    def test_resp2_user_password_uri
      config = Config.new(protocol: 2, url: "redis://username:password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "username", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
      assert_equal [%w[AUTH username password]], config.connection_prelude
    end

    def test_resp3_user_password_uri
      config = Config.new(url: "redis://username:password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "username", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
      assert_equal [%w[HELLO 3 AUTH username password]], config.connection_prelude
    end

    def test_resp2_frozen_prelude
      config = Config.new(protocol: 2, url: "redis://username:password@example.com")
      prelude = config.connection_prelude

      assert_equal [%w[AUTH username password]], prelude
      assert_equal true, prelude.frozen?
      assert_equal true, (prelude.all? { |commands| commands.frozen? })

      prelude.each do |commands|
        assert_equal true, (commands.all? { |arg| arg.frozen? })
      end
    end

    def test_resp3_frozen_prelude
      config = Config.new(url: "redis://username:password@example.com")
      prelude = config.connection_prelude

      assert_equal [%w[HELLO 3 AUTH username password]], prelude
      assert_equal true, prelude.frozen?
      assert_equal true, (prelude.all? { |commands| commands.frozen? })

      prelude.each do |commands|
        assert_equal true, (commands.all? { |arg| arg.frozen? })
      end
    end

    def test_resp2_simple_password_uri
      config = Config.new(protocol: 2, url: "redis://password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
      assert_equal [%w[AUTH password]], config.connection_prelude
    end

    def test_resp3_simple_password_uri
      config = Config.new(url: "redis://password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
      assert_equal [%w[HELLO 3 AUTH default password]], config.connection_prelude
    end

    def test_simple_password_uri_empty_user
      config = Config.new(url: "redis://:password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
      assert_equal [%w[HELLO 3 AUTH default password]], config.connection_prelude
    end

    def test_percent_encoded_password_uri
      # from https://redis.io/topics/rediscli#host-port-password-and-database
      config = Config.new(url: "redis://p%40ssw0rd@redis-16379.hosted.com:16379/12")
      assert_equal "redis-16379.hosted.com", config.host
      assert_equal 16379, config.port
      assert_equal "default", config.username
      assert_equal "p@ssw0rd", config.password
      assert_equal 12, config.db
      refute_predicate config, :ssl?
      assert_equal [%w[HELLO 3 AUTH default p@ssw0rd], %w[SELECT 12]], config.connection_prelude
    end

    def test_rediss_url
      config = Config.new(url: "rediss://example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_nil config.password
      assert_equal 0, config.db
      assert_predicate config, :ssl?
      assert_equal [%w[HELLO 3]], config.connection_prelude
    end

    def test_trailing_slash_url
      config = Config.new(url: "redis://example.com/")
      assert_equal 0, config.db
      assert_equal [%w[HELLO 3]], config.connection_prelude
      config = Config.new(url: "redis://[::1]/")
      assert_equal 0, config.db
      assert_equal [%w[HELLO 3]], config.connection_prelude
    end

    def test_overriding
      config = Config.new(
        url: "redis://p%40ssw0rd@redis-16379.hosted.com:16379/12",
        ssl: true,
        username: "george",
        password: "hunter2",
        host: "example.com",
        port: 12,
        db: 5,
      )

      assert_equal "example.com", config.host
      assert_equal 12, config.port
      assert_equal "george", config.username
      assert_equal "hunter2", config.password
      assert_equal 5, config.db
      assert_predicate config, :ssl?
      assert_equal [%w[HELLO 3 AUTH george hunter2], %w[SELECT 5]], config.connection_prelude
    end

    def test_server_url
      assert_equal "redis://localhost:6379", Config.new.server_url
      assert_equal "redis://localhost:6379", Config.new(username: "george", password: "hunter2").server_url
      assert_equal "redis://localhost:6379/5", Config.new(db: 5).server_url
      assert_equal "redis://192.168.0.1:6379", Config.new(host: "192.168.0.1", port: 6379).server_url
      assert_equal "redis://192.168.0.1:6379/5", Config.new(host: "192.168.0.1", port: 6379, db: 5).server_url
      assert_equal "redis://example.com:8080", Config.new(host: "example.com", port: 8080).server_url
      assert_equal "rediss://localhost:6379", Config.new(ssl: true).server_url
      assert_equal "redis://[::1]:6379", Config.new(host: "::1", port: 6379).server_url
      assert_equal "redis://[::1]:6379/2", Config.new(host: "::1", port: 6379, db: 2).server_url
      assert_equal "redis://[::1]:6379/2", Config.new(url: "redis://[::1]:6379/2").server_url
      assert_equal "redis://[ffff:aaaa:1111::fcf]:6379", Config.new(host: "ffff:aaaa:1111::fcf", port: 6379).server_url
      assert_equal "redis://[ffff:aaaa:1111::fcf]:6379/2", Config.new(host: "ffff:aaaa:1111::fcf", port: 6379, db: 2).server_url

      assert_equal "unix:///var/redis/redis.sock?db=5", Config.new(path: "/var/redis/redis.sock", db: 5).server_url
    end

    def test_custom_field
      config = Config.new(custom: { foo: "bar" })
      assert_equal({ foo: "bar" }, config.custom)
    end
  end
end
