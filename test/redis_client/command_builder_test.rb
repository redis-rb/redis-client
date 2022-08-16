# frozen_string_literal: true

require "test_helper"

class RedisClient
  class CommandBuilderTest < Minitest::Test
    def test_positional
      assert_equal ["a", "b", "c"], call("a", "b", "c")
    end

    def test_array
      assert_equal ["a", "b", "c"], call("a", ["b", "c"])
    end

    def test_hash
      assert_equal ["a", "b", "c"], call("a", { "b" => "c" })
    end

    def test_symbol
      assert_equal ["a", "b", "c", "d"], call(:a, { b: :c }, :d)
    end

    def test_numeric
      assert_equal ["1", "2.3"], call(1, 2.3)
    end

    def test_kwargs_boolean
      assert_equal ["withscores"], call(ttl: nil, ex: false, withscores: true)
    end

    def test_kwargs_values
      assert_equal ["ttl", "42"], call(ttl: 42)
    end

    def test_nil_kwargs
      assert_equal ["a", "b", "c"], CommandBuilder.generate(%i(a b c))
    end

    private

    def call(*args, **kwargs)
      CommandBuilder.generate(args, kwargs)
    end
  end
end
