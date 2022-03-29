# frozen_string_literal: true

require "test_helper"

class RedisClientTest < Minitest::Test
  include ClientTestHelper

  def test_has_version
    assert_instance_of String, RedisClient::VERSION
  end

  def test_config
    redis_config = RedisClient.config(**RedisServerHelper.tcp_config)
    redis = redis_config.new_client
    assert_equal "PONG", redis.call("PING")
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

  def test_keyword_arguments_casting
    assert_equal "OK", @redis.call("SET", "key", "val", ex: 5)
    assert_equal 5, @redis.call("TTL", "key")
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

  def test_empty_pipeline
    assert_equal([], @redis.pipelined { |_p| })
  end

  def test_large_read_pipelines
    @redis.timeout = 5
    @redis.call("LPUSH", "list", *1000.times.to_a)
    @redis.pipelined do |pipeline|
      100.times do
        pipeline.call("LRANGE", "list", 0, -1)
      end
    end
  end

  def test_large_write_pipelines
    @redis.timeout = 5
    @redis.pipelined do |pipeline|
      10.times do |i|
        pipeline.call("SET", i, i.to_s * 10485760)
      end
    end
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

  def test_call_once
    assert_equal 1, @redis.call_once("INCR", "counter")

    result = @redis.pipelined do |pipeline|
      pipeline.call_once("INCR", "counter")
    end
    assert_equal [2], result

    result = @redis.multi do |transaction|
      transaction.call_once("INCR", "counter")
    end
    assert_equal [3], result
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

  def test_empty_transaction
    result = @redis.multi do |_transaction|
    end
    assert_equal [], result
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

  def test_empty_transaction_watch_reset
    other_client = new_client

    @redis.multi(watch: ["foo"]) { |_t| }

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

  def test_set_client_id
    client = new_client(id: "peter")
    assert_includes client.call("CLIENT", "INFO"), " name=peter "
    client.call("CLIENT", "SETNAME", "steven")
    assert_includes client.call("CLIENT", "INFO"), " name=steven "
    client.close
    assert_includes client.call("CLIENT", "INFO"), " name=peter "
  end

  def test_call_timeout_false
    thr = Thread.start do
      client = new_client
      client.blocking_call(false, "BRPOP", "list", "0")
    end
    assert_nil thr.join(0.3) # still blocking
    @redis.call("LPUSH", "list", "token")
    refute_nil thr.join(0.3)
    assert_equal ["list", "token"], thr.value
  end

  def test_call_timeout_zero
    thr = Thread.start do
      client = new_client
      client.blocking_call(0, "BRPOP", "list", "0")
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
        pipeline.blocking_call(false, "BRPOP", "list", "0")
      end
    end
    assert_nil thr.join(0.3) # still blocking
    @redis.call("LPUSH", "list", "token")
    refute_nil thr.join(0.3)
    assert_equal [["list", "token"]], thr.value
  end

  def test_multi_call_timeout
    assert_raises NoMethodError do
      @redis.multi do |transaction|
        transaction.blocking_call(false, "BRPOP", "list", "0")
      end
    end
  end

  def test_blocking_call_timeout
    assert_nil @redis.blocking_call(0.2, "BRPOP", "list", "0.1")
    assert_equal "OK", @redis.call("SET", "foo", "bar")
  end

  def test_scan
    @redis.call("MSET", *100.times.to_a)
    keys = []
    @redis.scan("COUNT", "10") do |key|
      keys << key
    end
    expected_keys = 100.times.select(&:even?).map(&:to_s).sort
    assert_equal expected_keys, keys.sort
  end

  def test_scan_iterator
    @redis.call("MSET", *100.times.to_a)
    keys = @redis.scan(count: 10).to_a
    expected_keys = 100.times.select(&:even?).map(&:to_s).sort
    assert_equal expected_keys, keys.sort
  end

  def test_sscan
    @redis.call("SADD", "large-set", *100.times.to_a)
    elements = []
    @redis.sscan("large-set", "COUNT", "10") do |element|
      elements << element
    end
    expected_elements = *100.times.map(&:to_s).sort
    assert_equal expected_elements, elements.sort
  end

  def test_zscan
    @redis.call("ZADD", "large-set", *100.times.to_a)
    elements = {}
    @redis.zscan("large-set", "COUNT", "10") do |element, score|
      elements[element] = score
    end

    expected_elements = Hash[*100.times.map(&:to_s)].invert
    assert_equal expected_elements, elements
  end

  def test_hscan
    @redis.call("HMSET", "large-hash", *100.times.to_a)
    pairs = []
    @redis.hscan("large-hash", "COUNT", "10") do |key, value|
      pairs << [key, value]
    end
    expected_pairs = Hash[*100.times.map(&:to_s)].to_a
    assert_equal expected_pairs, pairs
  end
end
