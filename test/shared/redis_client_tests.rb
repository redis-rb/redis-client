# frozen_string_literal: true

module RedisClientTests
  def test_has_version
    assert_instance_of String, RedisClient::VERSION
  end

  def test_config
    assert_instance_of RedisClient::Config, @redis.config

    redis_config = RedisClient.config(**tcp_config)
    redis = redis_config.new_client
    assert_equal "PONG", redis.call("PING")
  end

  def test_id
    assert_nil @redis.id
  end

  def test_ping
    assert_equal "PONG", @redis.call("PING")
  end

  def test_empty_call
    assert_raises ArgumentError do
      @redis.call
    end

    assert_raises ArgumentError do
      @redis.blocking_call(false)
    end

    assert_raises ArgumentError do
      @redis.call([], [])
    end

    @redis.pipelined do |pipeline|
      assert_raises ArgumentError do
        pipeline.call
      end
    end

    @redis.multi do |transaction|
      assert_raises ArgumentError do
        transaction.call
      end
    end
  end

  def test_call_v
    assert_equal "OK", @redis.call(["SET", "str", 42])
    assert_equal "OK", @redis.blocking_call_v(1, ["SET", "str", 42])
    assert_equal "OK", @redis.call_once_v(["SET", "str", 42])

    results = @redis.pipelined do |pipeline|
      assert_nil pipeline.call(["SET", "str", 42])
      assert_nil pipeline.blocking_call_v(1, ["SET", "str", 42])
      assert_nil pipeline.call_once_v(["SET", "str", 42])
    end
    assert_equal %w(OK OK OK), results

    results = @redis.multi do |transaction|
      assert_nil transaction.call(["SET", "str", 42])
      assert_nil transaction.call_once_v(["SET", "str", 42])
    end
    assert_equal %w(OK OK), results

    assert_nil @redis.pubsub.call_v(["PING"])
  end

  def test_acts_as_pool
    assert_equal("PONG", @redis.with { |c| c.call("PING") })
    assert_instance_of Integer, @redis.size
  end

  def test_status_strings_are_frozen
    assert_predicate @redis.call("SET", "str", "42"), :frozen?
    assert_predicate @redis.call("PING"), :frozen?
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
    assert_equal ["3", "2", "1"], @redis.call("LRANGE", "list", 0, 3)

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
    assert_equal ["3", "2", "1"], @redis.call("LRANGE", "list", 0, 3)

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
    @redis.call("LPUSH", "list", *1000.times.to_a)
    @redis.pipelined do |pipeline|
      100.times do
        pipeline.call("LRANGE", "list", 0, -1)
      end
    end
  end

  def test_large_write_pipelines
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
    error = assert_raises RedisClient::CommandError do
      @redis.pipelined do |pipeline|
        pipeline.call("DOESNOTEXIST", 12)
        pipeline.call("SET", "foo", "42")
      end
    end

    assert_equal ["DOESNOTEXIST", "12"], error.command

    assert_equal "42", @redis.call("GET", "foo")
  end

  def test_pipelining_error_with_explicit_raising_exception
    error = assert_raises RedisClient::CommandError do
      @redis.pipelined(exception: true) do |pipeline|
        pipeline.call("DOESNOTEXIST", 12)
        pipeline.call("SET", "foo", "42")
      end
    end

    assert_equal ["DOESNOTEXIST", "12"], error.command

    assert_equal "42", @redis.call("GET", "foo")
  end

  def test_pipelining_error_without_raising_exception
    result = @redis.pipelined(exception: false) do |pipeline|
      pipeline.call("DOESNOTEXIST", 12)
      pipeline.call("SET", "foo", "42")
    end

    assert result[0].is_a?(RedisClient::CommandError)
    assert_equal ["DOESNOTEXIST", "12"], result[0].command

    assert_equal "OK", result[1]

    assert_equal "42", @redis.call("GET", "foo")
  end

  def test_multi_error
    error = assert_raises RedisClient::CommandError do
      @redis.multi do |pipeline|
        pipeline.call("DOESNOTEXIST", 12)
        pipeline.call("SET", "foo", "42")
      end
    end

    assert_equal ["DOESNOTEXIST", "12"], error.command

    assert_nil @redis.call("GET", "foo")
  end

  def test_wrong_type
    @redis.call("SET", "str", "hello")

    error = assert_raises RedisClient::CommandError do
      @redis.call("SISMEMBER", "str", "member")
    end
    assert_equal ["SISMEMBER", "str", "member"], error.command
    assert_match(/WRONGTYPE Operation against a key holding the wrong kind of value (.*:.*)/, error.message)

    error = assert_raises RedisClient::CommandError do
      @redis.pipelined do |pipeline|
        pipeline.call("SISMEMBER", "str", "member")
      end
    end
    assert_equal ["SISMEMBER", "str", "member"], error.command
    assert_match(/WRONGTYPE Operation against a key holding the wrong kind of value (.*:.*)/, error.message)

    error = assert_raises RedisClient::CommandError do
      @redis.multi do |transaction|
        transaction.call("SISMEMBER", "str", "member")
      end
    end
    assert_equal ["SISMEMBER", "str", "member"], error.command
    assert_match(/WRONGTYPE Operation against a key holding the wrong kind of value (.*:.*)/, error.message)
  end

  def test_command_missing
    error = assert_raises RedisClient::CommandError do
      @redis.call("DOESNOTEXIST", "foo")
    end
    assert_match(/ERR unknown command .DOESNOTEXIST.*\(.*:.*\)/, error.message)
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
        pipeline.blocking_call(false, "BRPOP", "list", "0") { |r| r.map(&:upcase) }
      end
    end
    assert_nil thr.join(0.3) # still blocking
    @redis.call("LPUSH", "list", "token")
    refute_nil thr.join(0.3)
    assert_equal [["LIST", "TOKEN"]], thr.value
  end

  def test_multi_call_timeout
    assert_raises NoMethodError do
      @redis.multi do |transaction|
        transaction.blocking_call(false, "BRPOP", "list", "0")
      end
    end
  end

  def test_blocking_call_timeout
    assert_nil @redis.blocking_call(0.5, "BRPOP", "list", "0.1")
    assert_equal "OK", @redis.call("SET", "foo", "bar")
  end

  def test_blocking_call_timeout_retries
    redis = new_client(reconnect_attempts: [3.0])
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    assert_raises RedisClient::ReadTimeoutError do
      redis.blocking_call(0.1, "BRPOP", "list", "0.1")
    end
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    assert duration < 0.5 # if we retried we'd have waited much long
  end

  def test_scan
    @redis.call("MSET", *100.times.to_a)
    expected_keys = 100.times.select(&:even?).map(&:to_s).sort

    keys = []
    @redis.scan do |key|
      keys << key
    end
    assert_equal expected_keys, keys.sort

    keys = []
    @redis.scan("COUNT", "10") do |key|
      keys << key
    end
    assert_equal expected_keys, keys.sort
  end

  def test_scan_iterator
    @redis.call("MSET", *100.times.to_a)
    expected_keys = 100.times.select(&:even?).map(&:to_s).sort

    keys = @redis.scan.to_a
    assert_equal expected_keys, keys.sort

    keys = @redis.scan(count: 10).to_a
    assert_equal expected_keys, keys.sort
  end

  def test_sscan
    @redis.call("SADD", "large-set", *100.times.to_a)
    expected_elements = *100.times.map(&:to_s).sort

    elements = []
    @redis.sscan("large-set") do |element|
      elements << element
    end
    assert_equal expected_elements, elements.sort

    elements = @redis.sscan("large-set").to_a
    assert_equal expected_elements, elements.sort

    elements = []
    @redis.sscan("large-set", "COUNT", "10") do |element|
      elements << element
    end
    assert_equal expected_elements, elements.sort
  end

  def test_zscan
    @redis.call("ZADD", "large-set", *100.times.to_a)
    expected_elements = Hash[*100.times.map(&:to_s)].invert

    elements = {}
    @redis.zscan("large-set") do |element, score|
      elements[element] = score
    end
    assert_equal expected_elements, elements

    elements = @redis.zscan("large-set").to_a.to_h
    assert_equal expected_elements, elements

    elements = {}
    @redis.zscan("large-set", "COUNT", "10") do |element, score|
      elements[element] = score
    end
    assert_equal expected_elements, elements
  end

  def test_hscan
    @redis.call("HMSET", "large-hash", *100.times.to_a)
    expected_pairs = Hash[*100.times.map(&:to_s)].to_a

    pairs = []
    @redis.hscan("large-hash") do |key, value|
      pairs << [key, value]
    end
    assert_equal expected_pairs, pairs

    pairs = @redis.hscan("large-hash").to_a
    assert_equal expected_pairs, pairs

    pairs = []
    @redis.hscan("large-hash", "COUNT", "10") do |key, value|
      pairs << [key, value]
    end
    assert_equal expected_pairs, pairs
  end

  def test_timeouts_are_adjustable_on_the_client
    @redis.close
    @redis.connect_timeout = 1
    @redis.read_timeout = 1
    @redis.write_timeout = 1

    @redis.call("PING")
    @redis.connect_timeout = 2
    @redis.read_timeout = 2
    @redis.write_timeout = 2
  end

  def test_custom_result_casting
    assert_equal(0, @redis.call("SISMEMBER", "set", "unknown"))
    assert_equal(false, @redis.call("SISMEMBER", "set", "unknown") { |m| m > 0 })
    assert_equal([false], @redis.pipelined { |p| p.call("SISMEMBER", "set", "unknown") { |m| m > 0 } })
    assert_equal([false], @redis.multi { |p| p.call("SISMEMBER", "set", "unknown") { |m| m > 0 } })
  end

  def test_verbatim_string_reply
    assert_equal("# Server", @redis.call("INFO")[0..7])
  end

  def test_resp2_nil_string
    @redis = new_client(protocol: 2)
    @redis.call("SET", "foo", "bar")
    assert_equal "bar", @redis.call("GETDEL", "foo")
    assert_nil @redis.call("GET", "foo")
  end

  def test_resp2_limited_type_casting
    @redis = new_client(protocol: 2)
    assert_equal 1, @redis.call("INCR", "foo")
    @redis.call("HMSET", "hash", "foo", "bar")
    assert_equal ["foo", "bar"], @redis.call("HGETALL", "hash")
  end

  if Process.respond_to?(:fork)
    def test_handle_fork
      pid = fork do
        1000.times do
          assert_equal "OK", @redis.call("SET", "key", "foo")
        end
      end
      1000.times do
        assert_equal "PONG", @redis.call("PING")
      end
      _, status = Process.wait2(pid)
      assert_predicate(status, :success?)
    end

    def test_closing_in_child_doesnt_impact_parent
      pid = fork do
        @redis.close
        exit(0)
      end

      _, status = Process.wait2(pid)
      assert_predicate(status, :success?)

      assert_equal "PONG", @redis.call("PING")
    end
  end
end
