# frozen_string_literal: true

require "test_helper"

class RedisClient
  module DecoratorTests
    include ClientTestHelper
    include RedisClientTests

    module Commands
      def exists?(key)
        call("EXISTS", key) { |c| c > 0 }
      end
    end

    MyDecorator = Decorator.create(Commands)
    class MyDecorator
      def test?
        true
      end
    end

    def test_custom_command_helpers
      @redis.call("SET", "key", "hello")
      assert_equal 1, @redis.call("EXISTS", "key")
      assert_equal true, @redis.exists?("key")
      assert_equal([true], @redis.pipelined { |p| p.exists?("key") })
      assert_equal([true], @redis.multi { |p| p.exists?("key") })
    end

    def test_client_methods_not_available_on_pipelines
      assert_equal true, @redis.test?

      @redis.pipelined do |pipeline|
        assert_equal false, pipeline.respond_to?(:test?)
      end

      @redis.multi do |pipeline|
        assert_equal false, pipeline.respond_to?(:test?)
      end
    end
  end

  class DecoratorTest < RedisClientTestCase
    include DecoratorTests

    private

    def new_client(**overrides)
      MyDecorator.new(RedisClient.config(**tcp_config.merge(overrides)).new_client)
    end
  end

  class PooledDecoratorTest < RedisClientTestCase
    include DecoratorTests

    private

    def new_client(**overrides)
      MyDecorator.new(RedisClient.config(**tcp_config.merge(overrides)).new_pool)
    end
  end
end
