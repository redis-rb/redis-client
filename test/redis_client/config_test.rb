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

    def test_user_password_uri
      config = Config.new(url: "redis://username:password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "username", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
    end

    def test_frozen_prelude
      config = Config.new(url: "redis://username:password@example.com")
      prelude = config.connection_prelude
      assert_equal true, prelude.frozen?
      assert_equal true, (prelude.all? { |commands| commands.frozen? })

      prelude.each do |commands|
        assert_equal true, (commands.all? { |arg| arg.frozen? })
      end
    end

    def test_simple_password_uri
      config = Config.new(url: "redis://password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
    end

    def test_simple_password_uri_empty_user
      config = Config.new(url: "redis://:password@example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_equal "password", config.password
      assert_equal 0, config.db
      refute_predicate config, :ssl?
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
    end

    def test_rediss_url
      config = Config.new(url: "rediss://example.com")
      assert_equal "example.com", config.host
      assert_equal 6379, config.port
      assert_equal "default", config.username
      assert_nil config.password
      assert_equal 0, config.db
      assert_predicate config, :ssl?
    end

    def test_trailing_slash_url
      config = Config.new(url: "redis://example.com/")
      assert_equal 0, config.db
      config = Config.new(url: "redis://[::1]/")
      assert_equal 0, config.db
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
    end

    def test_server_url
      assert_equal "redis://localhost:6379/0", Config.new.server_url
      assert_equal "redis://localhost:6379/0", Config.new(username: "george", password: "hunter2").server_url
      assert_equal "redis://localhost:6379/5", Config.new(db: 5).server_url
      assert_equal "redis://example.com:8080/0", Config.new(host: "example.com", port: 8080).server_url
      assert_equal "rediss://localhost:6379/0", Config.new(ssl: true).server_url

      assert_equal "/var/redis/redis.sock/5", Config.new(path: "/var/redis/redis.sock", db: 5).server_url
    end

    def test_custom_field
      config = Config.new(custom: { foo: "bar" })
      assert_equal({ foo: "bar" }, config.custom)
    end
  end
end
