# frozen_string_literal: true

require "test_helper"

class RedisClient
  class RESP3Test < Minitest::Test
    def test_dump_string
      assert_dumps "Hello World!", "$12\r\nHello World!\r\n"
      assert_dumps "Hello\r\nWorld!", "$13\r\nHello\r\nWorld!\r\n"
    end

    def test_dump_integer
      assert_dumps 42, ":42\r\n"
    end

    def test_dump_true
      assert_dumps true, "#t\r\n"
    end

    def test_dump_false
      assert_dumps false, "#f\r\n"
    end

    def test_dump_nil
      assert_dumps nil, "_\r\n"
    end

    def test_dump_big_integer
      assert_dumps 1_000_000_000_000_000_000_000, "(1000000000000000000000\r\n"
    end

    def test_dump_float
      assert_dumps 42.42, ",42.42\r\n"
      assert_dumps Float::INFINITY, ",inf\r\n"
      assert_dumps(-Float::INFINITY, ",-inf\r\n")
    end

    def test_dump_array
      assert_dumps [1, 2, 3], "*3\r\n:1\r\n:2\r\n:3\r\n"
    end

    def test_dump_set
      assert_dumps Set[1, 2, 3], "~3\r\n:1\r\n:2\r\n:3\r\n"
    end

    def test_dump_hash
      assert_dumps({ 'first' => 1, 'second' => 2 }, "%2\r\n$5\r\nfirst\r\n:1\r\n$6\r\nsecond\r\n:2\r\n")
    end

    def test_load_blob_string
      assert_parses "Hello World!", "$12\r\nHello World!\r\n"
    end

    def test_load_simple_string
      assert_parses "Hello World!", "+Hello World!\r\n"
    end

    def test_load_error
      assert_parses CommandError.parse("SOMEERROR"), "-SOMEERROR\r\n"
    end

    def test_load_integer
      assert_parses 42, ":42\r\n"
      assert_parses(-42, ":-42\r\n")
      assert_parses 3_492_890_328_409_238_509_324_850_943_850_943_825_024_385, "(3492890328409238509324850943850943825024385\r\n"
    end

    def test_load_double
      assert_parses 42.42, ",42.42\r\n"
      assert_parses(-42.42, ",-42.42\r\n")
      assert_parses Float::INFINITY, ",inf\r\n"
      assert_parses(-Float::INFINITY, ",-inf\r\n")
    end

    def test_load_null
      assert_parses nil, "_\r\n"
    end

    def test_load_boolean
      assert_parses true, "#t\r\n"
      assert_parses false, "#f\r\n"
    end

    def test_load_array
      assert_parses [1, 2, 3], "*3\r\n:1\r\n:2\r\n:3\r\n"
    end

    def test_load_set
      assert_parses Set['orange', 'apple', true, 100, 999], "~5\r\n+orange\r\n+apple\r\n#t\r\n:100\r\n:999\r\n"
    end

    def test_load_map
      assert_parses({ 'first' => 1, 'second' => 2 }, "%2\r\n+first\r\n:1\r\n+second\r\n:2\r\n")
    end

    private

    def assert_parses(expected, payload)
      io = StringIO.new(payload.b)
      if expected.nil?
        assert_nil RESP3.load(io)
      else
        assert_equal(expected, RESP3.load(io))
      end

      assert io.eof?, "Expected IO to be fully consumed: #{io.read.inspect}"
    end

    def assert_dumps(payload, expected)
      assert_equal expected.encode(Encoding::BINARY), RESP3.dump(payload)
    end
  end
end
