# frozen_string_literal: true

require "test_helper"

class RedisClientTest < Minitest::Test
  def setup
    @redis = new_client
    @redis.call("FLUSHDB")
  end

  def test_has_version
    assert_instance_of String, RedisClient::VERSION
  end

  def test_ping
    assert_equal "PONG", @redis.call("PING")
  end

  def test_argument_casting_numeric
    assert_equal "OK", @redis.call("SET", "str", 42)
    assert_equal "42", @redis.call("GET", "str")

    assert_equal "OK", @redis.call("SET", "str", 4.2)
    assert_equal "4.2", @redis.call("GET", "str")
  end

  def test_argument_casting_symbol
    assert_equal "OK", @redis.call("SET", :str, 42)
    assert_equal "42", @redis.call(:GET, "str")
  end

  def test_argument_casting_unsupported
    assert_raises TypeError do
      @redis.call("SET", "str", nil) # Could be casted as empty string, but would likely hide errors
    end

    assert_raises TypeError do
      @redis.call("SET", "str", true) # Unclear how it should be casted
    end

    assert_raises TypeError do
      @redis.call("SET", "str", false) # Unclear how it should be casted
    end
  end

  def test_argument_casting_arrays
    assert_equal 3, @redis.call("LPUSH", "list", [1, 2, 3])
    assert_equal ["1", "2", "3"], @redis.call("RPOP", "list", 3)

    error = assert_raises TypeError do
      @redis.call("LPUSH", "list", [1, [2, 3]])
    end
    assert_includes error.message, "Unsupported command argument type: Array"

    error = assert_raises TypeError do
      @redis.call("LPUSH", "list", [1, { 2 => 3 }])
    end
    assert_includes error.message, "Unsupported command argument type: Hash"
  end

  def test_argument_casting_hashes
    assert_equal "OK", @redis.call("HMSET", "hash", { "bar" => 1, "baz" => 2 })
    assert_equal({ "bar" => "1", "baz" => "2" }, @redis.call("HGETALL", "hash"))

    error = assert_raises TypeError do
      @redis.call("HMSET", "hash", { "bar" => [1, 2] })
    end
    assert_includes error.message, "Unsupported command argument type: Array"

    error = assert_raises TypeError do
      @redis.call("HMSET", "hash", { "bar" => { 1 => 2 } })
    end
    assert_includes error.message, "Unsupported command argument type: Hash"
  end

  def test_pipeline_argument_casting_numeric
    assert_equal(["OK"], @redis.pipelined { |p| p.call("SET", "str", 42) })
    assert_equal "42", @redis.call("GET", "str")

    assert_equal(["OK"], @redis.pipelined { |p| p.call("SET", "str", 4.2) })
    assert_equal "4.2", @redis.call("GET", "str")
  end

  def test_pipeline_argument_casting_symbol
    assert_equal(["OK"], @redis.pipelined { |p| p.call("SET", :str, 42) })
    assert_equal "42", @redis.call(:GET, "str")
  end

  def test_pipeline_argument_casting_arrays
    assert_equal([3], @redis.pipelined { |p| p.call("LPUSH", "list", [1, 2, 3]) })
    assert_equal ["1", "2", "3"], @redis.call("RPOP", "list", 3)

    error = assert_raises TypeError do
      @redis.pipelined { |p| p.call("LPUSH", "list", [1, [2, 3]]) }
    end
    assert_includes error.message, "Unsupported command argument type: Array"

    error = assert_raises TypeError do
      @redis.pipelined { |p| p.call("LPUSH", "list", [1, { 2 => 3 }]) }
    end
    assert_includes error.message, "Unsupported command argument type: Hash"
  end

  def test_pipeline_argument_casting_hashes
    assert_equal(["OK"], @redis.pipelined { |p| p.call("HMSET", "hash", { "bar" => 1, "baz" => 2 }) })
    assert_equal({ "bar" => "1", "baz" => "2" }, @redis.call("HGETALL", "hash"))

    error = assert_raises TypeError do
      @redis.pipelined { |p| p.call("HMSET", "hash", { "bar" => [1, 2] }) }
    end
    assert_includes error.message, "Unsupported command argument type: Array"

    error = assert_raises TypeError do
      @redis.pipelined { |p| p.call("HMSET", "hash", { "bar" => { 1 => 2 } }) }
    end
    assert_includes error.message, "Unsupported command argument type: Hash"
  end

  def test_get_set
    string = "a" * 15_000
    assert_equal "OK", @redis.call("SET", "foo", string)
    assert_equal string, @redis.call("GET", "foo")
  end

  def test_hashes
    @redis.call("HMSET", "foo", "bar", "1", "baz", "2")
    assert_equal({ "bar" => "1", "baz" => "2" }, @redis.call("HGETALL", "foo"))
  end

  def test_pipelining
    result = @redis.pipelined do |pipeline|
      assert_nil pipeline.call("SET", "foo", "42")
      assert_equal "OK", @redis.call("SET", "foo", "21") # Not pipelined
      assert_nil pipeline.call("EXPIRE", "foo", "100")
    end
    assert_equal ["OK", 1], result
  end

  def test_pipelining_error
    assert_raises RedisClient::CommandError do
      @redis.pipelined do |pipeline|
        pipeline.call("DOESNOTEXIST")
        pipeline.call("SET", "foo", "42")
      end
    end

    assert_equal "42", @redis.call("GET", "foo")
  end

  def test_command_missing
    error = assert_raises RedisClient::CommandError do
      @redis.call("DOESNOTEXIST", "foo")
    end
    assert error.message.start_with?("ERR unknown command `DOESNOTEXIST`")
  end

  def test_authentication
    @redis.call("ACL", "SETUSER", "AzureDiamond", ">hunter2", "on", "+PING")

    client = new_client(username: "AzureDiamond", password: "hunter2")
    assert_equal "PONG", client.call("PING")

    assert_raises RedisClient::PermissionError do
      client.call("GET", "foo")
    end

    client = new_client(username: "AzureDiamond", password: "trolilol")
    assert_raises RedisClient::AuthenticationError do
      client.call("PING")
    end
  end

  def test_transaction
    result = @redis.multi do |transaction|
      transaction.call("SET", "foo", "1")
      transaction.call("EXPIRE", "foo", "42")
    end
    assert_equal ["OK", 1], result
  end

  def test_transaction_abort
    other_client = new_client

    @redis.call("SET", "foo", "1")

    result = @redis.multi(watch: ["foo"]) do |transaction|
      counter = Integer(@redis.call("GET", "foo"))

      other_client.call("SET", "foo", "2")

      transaction.call("SET", "foo", (counter + 1).to_s)
      transaction.call("EXPIRE", "foo", "42")
    end
    assert_nil result
  end

  def test_transaction_watch_reset
    other_client = new_client

    assert_raises RuntimeError do
      @redis.multi(watch: ["foo"]) do |_transaction|
        raise "oops"
      end
    end

    result = @redis.multi do |transaction|
      other_client.call("SET", "foo", "2")
      transaction.call("SET", "foo", "3")
    end
    assert_equal ["OK"], result
    assert_equal "3", @redis.call("GET", "foo")
  end

  def test_preselect_database
    client = new_client(db: 5)
    assert_includes client.call("CLIENT", "INFO"), " db=5 "
    client.call("SELECT", 6)
    assert_includes client.call("CLIENT", "INFO"), " db=6 "
    client.close
    assert_includes client.call("CLIENT", "INFO"), " db=5 "
  end

  def test_call_timeout
    thr = Thread.start do
      client = new_client
      client.call("BRPOP", "list", "0", timeout: false)
    end
    assert_nil thr.join(0.3) # still blocking
    @redis.call("LPUSH", "list", "token")
    refute_nil thr.join(0.3)
    assert_equal ["list", "token"], thr.value
  end

  def test_pipelined_call_timeout
    thr = Thread.start do
      client = new_client
      client.pipelined do |pipeline|
        pipeline.call("BRPOP", "list", "0", timeout: false)
      end
    end
    assert_nil thr.join(0.3) # still blocking
    @redis.call("LPUSH", "list", "token")
    refute_nil thr.join(0.3)
    assert_equal [["list", "token"]], thr.value
  end

  def test_multi_call_timeout
    error = assert_raises ArgumentError do
      @redis.multi do |transaction|
        transaction.call("BRPOP", "list", "0", timeout: false)
      end
    end
    assert_includes error.message, "Redis transactions don't support per command timeouts."
  end

  private

  def new_client(**overrides)
    RedisClient.new(**RedisServerHelper.tcp_config.merge(overrides))
  end
end
