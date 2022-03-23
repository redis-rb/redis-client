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

    def test_simple_password_uri
      config = Config.new(url: "redis://password@example.com")
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
  end
end
