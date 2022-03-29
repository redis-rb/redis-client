# RedisClient

`redis-client` is a simple, low-level, client for Redis 6+.

Contrary to the `redis` gem, `redis-client` doesn't try to map all redis commands to Ruby constructs,
it merely is a thin wrapper on top of the RESP3 protocol.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-client'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install redis-client

## Usage

To use `RedisClient` you first define a connection configuration, from which you can create clients:

```ruby
redis_config = RedisClient.config(host: "10.0.1.1", port: 6380, db: 15)
redis = redis_config.new_client
redis.call("SET", "mykey", "hello world") # => "OK"
redis.call("GET", "mykey") # => "hello world"
```

For simple use cases where only a single connection is needed, you can use the `RedisClient.new` shortcut:

```ruby
redis = RedisClient.new
redis.call("GET", "mykey")
```

NOTE: `RedisClient` instances must not be shared between threads. Make sure to read the section on [thread safety](#thread-safety).

### Configuration

- `url`: A Redis connection URL, e.g. `redis://example.com:6379/5`, a `rediss://` scheme enable SSL, and the path is interpreted as a database number.
  Note tht all other configurtions take precedence, e.g. `RedisClient.config(url: "redis://localhost:3000" port: 6380)` will connect on port `6380`.
- `host`: The server hostname or IP address. Defaults to `"localhost"`.
- `port`: The server port. Defaults to `6379`.
- `path`: The path to a UNIX socket, if set `url`, `host` and `port` are ignored.
- `db`: The database to select after connecting, defaults to `0`.
- `id` ID for the client connection, assigns name to current connection by sending `CLIENT SETNAME`.
- `username` Username to authenticate against server, defaults to `"default"`.
- `password` Password to authenticate against server.
- `timeout`: The general timeout in seconds, default to `1.0`.
- `connect_timeout`: The connection timeout, takes precedence over the general timeout when connecting to the server.
- `read_timeout`: The read timeout, takes precedence over the general timeout when reading responses from the server.
- `write_timeout`: The write timeout, takes precedence over the general timeout when sending commands to the server.
- `reconnect_attempts`: Specify how many times the client should retry to send queries. Defaults to `0`. Makes sure to read the [reconnection section](#reconnection) before enabling it.

### Type support

Only a select few Ruby types are supported as arguments beside strings.

Integer and Float are supported:

```ruby
redis.call("SET", "mykey", 42)
redis.call("SET", "mykey", 1.23)
```

is equivalent to:

```ruby
redis.call("SET", "mykey", 42.to_s)
redis.call("SET", "mykey", 1.23.to_s)
```

Arrays are flattened as arguments:

```ruby
redis.call("LPUSH", "list", [1, 2, 3], 4)
```

is equivalent to:

```ruby
redis.call("LPUSH", "list", "1", "2", "3", "4")
```

Hashes are flatenned as well:

```ruby
redis.call("HMSET", "hash", foo: 1, bar: 2)
redis.call("SET", "key", "value", ex: 5)
```

is equivalent to:

```ruby
redis.call("HMSET", "hash", "foo", "1", "bar", "2")
redis.call("SET", "key", "value", "ex", "5")
```

Any other type requires the caller to explictly cast the argument as a string.

### Blocking commands

For blocking commands such as `BRPOP`, a custom timeout duration can be passed as first argument of the `#blocking_call` method:

```
redis.blocking_call(timeout, "BRPOP", "key", 0)
```

If `timeout` is reached, `#blocking_call` returns `nil`.

`timeout` is expressed in seconds, you can pass `false` or `0` to mean no timeout.

### Scan commands

For easier use of the [`SCAN` family of commands](https://redis.io/commands/scan), `#scan`, `#sscan`, `#hscan` and `#zscan` methods are provided

```ruby
redis.scan("MATCH", "pattern:*") do |key|
  ...
end
```

```ruby
redis.sscan("myset", "MATCH", "pattern:*") do |key|
  ...
end
```

For `HSCAN` and `ZSCAN`, pairs are yielded

```ruby
redis.hscan("myhash", "MATCH", "pattern:*") do |key, value|
  ...
end
```

```ruby
redis.zscan("myzset") do |element, score|
  ...
end
```

In all cases the `cursor` parameter must be omitted and starts at `0`.

### Pipelining

When multiple commands are executed sequentially, but are not dependent, the calls can be pipelined.
This means that the client doesn't wait for reply of the first command before sending the next command.
The advantage is that multiple commands are sent at once, resulting in faster overall execution.

The client can be instructed to pipeline commands by using the `#pipelined method`.
After the block is executed, the client sends all commands to Redis and gathers their replies.
These replies are returned by the `#pipelined` method.

```ruby
redis.pipelined do |pipeline|
  pipeline.call("SET", "foo", "bar") # => nil
  pipeline.call("INCR", "baz") # => nil
end
# => ["OK", 1]
```

### Transactions

You can use [`MULTI/EXEC` to run a number of commands in an atomic fashion](https://redis.io/topics/transactions).
This is similar to executing a pipeline, but the commands are
preceded by a call to `MULTI`, and followed by a call to `EXEC`. Like
the regular pipeline, the replies to the commands are returned by the
`#multi` method.

```ruby
redis.multi do |transaction|
  transaction.call("SET", "foo", "bar") # => nil
  transaction.call("INCR", "baz") # => nil
end
# => ["OK", 1]
```

For optimistic locking, the watched keys can be passed to the `#multi` method:

```ruby
redis.multi(watch: ["title"]) do |transaction|
  title = redis.call("GET", "title")
  transaction.call("SET", "title", title.upcase)
end
# => ["OK"] / nil
```

If the transaction wasn't successful, `#multi` will return `nil`.

Note that transactions using optimistic locking aren't automatically retried uppon connection errors.

### Publish / Subscribe

Pub/Sub related commands must be called on a dedicated `PubSub` object:

```ruby
redis = RedisClient.new
pubsub = redis.pubsub
pubsub.call("SUBSCRIBE", "channel-1", "channel-2")

loop do
  if message = pubsub.next_event(timeout)
    message # => ["subscribe", "channel-1", 1]
  else
    # no new message was received in the allocated timeout
  end
end
```

## Production

### Timeouts

The client allows you to configure connect, read, and write timeouts.
Passing a single `timeout` option will set all three values:

```ruby
RedisClient.config(timeout: 1).new
```

But you can use specific values for each of them:

```ruby
RedisClient.config(
  connect_timeout: 0.2,
  read_timeout: 1.0,
  write_timeout: 0.5,
).new
```

All timeout values are specified in seconds.

### Reconnection

`redis-client` support automatic reconnection after network errors via the `reconnect_attempts:` configuration option.

It can be set as a number of retries:

```ruby
redis_config = RedisClient.config(reconnect_attempts: 1)
```

Or as a list of sleep durations for implementing exponential backoff:

```ruby
redis_config = RedisClient.config(reconnect_attempts: [0, 0.05, 0.1])
```

**Important Note**: Retrying may cause commands to be issued more than once to the server, so in the case of
non-idempotent commands such as `LPUSH` or `INCR`, it may cause consistency issues.

To selectively disable automatic retries, you can use the `#call_once` method:

```ruby
redis_config = RedisClient.config(reconnect_attempts: [0, 0.05, 0.1])
redis = redis_config.new_client
redis.call("GET", "counter") # Will be retried up to 3 times.
redis.call_once("INCR", "counter") # Won't be retried.
```

### Thread Safety

Contrary to the `redis` gem, `redis-client` doesn't protect against concurrent access.
To use `redis-client` in concurrent environments, you MUST use a connection pool like [the `connection_pool` gem](https://rubygems.org/gems/connection_pool), or
have one client per Thread or Fiber.

```ruby
redis_config = RedisClient.config(host: "redis.example.com")
pool = ConnectionPool.new { redis_config.new_client }
pool.with do |redis|
  redis.call("PING")
end
```

### Fork Safety

`redis-client` doesn't try to detect forked processes. You MUST disconnect all clients before forking your process.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/redis-rb/redis-client.
