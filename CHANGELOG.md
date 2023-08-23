# Unreleased

- Adds `sentinel_username` and `sentinel_password` options for `RedisClient#sentinel`

# 0.16.0

- Add `RedisClient#disable_reconnection`.
- Reverted the special discard of connection. A regular `close(2)` should be enough.

# 0.15.0

- Discard sockets rather than explictly close them when a fork is detected. #126.
- Allow to configure sentinel client via url. #117.
- Fix sentinel to preverse the auth/password when refreshing the sentinel list. #107.

# 0.14.1

- Include the timeout value in TimeoutError messages.
- Fix connection keep-alive on FreeBSD. #102.

# 0.14.0

- Implement Sentinels list automatic refresh.
- hiredis binding now implement GC compaction and write barriers.
- hiredis binding now properly release the GVL around `connect(2)`.
- hiredis the client memory is now re-used on reconnection when possible to reduce allocation churn.

# 0.13.0

- Enable TCP keepalive on redis sockets. It sends a keep alive probe every 15 seconds for 2 minutes. #94.

# 0.12.2

- Cache calls to `Process.pid` on Ruby 3.1+. #91.

# 0.12.1

- Improve compatibility with `uri 0.12.0` (default in Ruby 3.2.0).

# 0.12.0

- hiredis: fix a compilation issue on macOS and Ruby 3.2.0. See: #79
- Close connection on MASTERDOWN errors. Similar to READONLY.
- Add a `circuit_breaker` configuration option for cache servers and other disposable Redis servers. See #55 / #70

# 0.11.2

- Close connection on READONLY errors. Fix: #64
- Handle Redis 6+ servers with a missing HELLO command. See: #67
- Validate `url` parameters a bit more strictly. Fix #61

# 0.11.1

- hiredis: Workaround a compilation bug with Xcode 14.0. Fix: #58
- Accept `URI` instances as `uri` parameter.

# 0.11.0

- hiredis: do not eagerly close the connection on read timeout, let the caller decide if a timeout is final.
- Add `Config#custom` to store configuration metadata. It can be used for per server middleware configuration.

# 0.10.0

- Added instance scoped middlewares. See: #53
- Allow subclasses of accepted types as command arguments. Fix: #51
- Improve hiredis driver error messages.

# 0.9.0

- Automatically reconnect if the process was forked.

# 0.8.1

- Make the client resilient to `Timeout.timeout` or `Thread#kill` use (it still is very much discouraged to use either).
  Use of async interrupts could cause responses to be interleaved.
- hiredis: handle commands returning a top-level `false` (no command does this today, but some extensions might).
- Workaround a bug in Ruby 2.6 causing a crash if the `debug` gem is enabled when `redis-client` is being required. Fix: #48

# 0.8.0

- Add a `connect` interface to the instrumentation API.

# 0.7.4

- Properly parse script errors on pre 7.0 redis server.

# 0.7.3

- Fix a bug in `url` parsing conflicting with the `path` option.

# 0.7.2

- Raise a distinct `RedisClient::OutOfMemoryError`, for Redis `OOM` errors.
- Fix the instrumentation API to be called even for authentication commands.
- Fix `url:` configuration to accept a trailing slash.

# 0.7.1

- Fix `#pubsub` being called when reconnection is disabled (redis-rb compatibility fix).

# 0.7.0

- Sentinel config now accept a list of URLs: `RedisClient.sentinel(sentinels: %w(redis://example.com:7000 redis://example.com:7001 ..))`

# 0.6.2

- Fix sentinel to not connected to s_down or o_down replicas.

# 0.6.1

- Fix `REDIS_REPLY_SET` parsing in `hiredis`.

# 0.6.0

- Added `protocol: 2` options to talk with Redis 5 and older servers.
- Added `_v` versions of `call` methods to make it easier to pass commands as arrays without splating.
- Fix calling `blocking_call` with a block in a pipeline.
- `blocking_call` now raise `ReadTimeoutError` if the command didn't complete in time.
- Fix `blocking_call` to not respect `retry_attempts` on timeout.
- Stop parsing RESP3 sets as Ruby Set instances.
- Fix `SystemStackError` when parsing very large hashes. Fix: #30
- `hiredis` now more properly release the GVL when doing IOs.

# 0.5.1

- Fix a regression in the `scan` familly of methods, they would raise with `ArgumentError: can't issue an empty redis command`. Fix: #24

# 0.5.0

- Fix handling of connection URLs with empty passwords (`redis://:pass@example.com`).
- Handle URLs with IPv6 hosts.
- Add `RedisClient::Config#server_url` as a quick way to identify which server the client is pointing to.
- Add `CommandError#command` to expose the command that caused the error.
- Raise a more explicit error when connecting to older redises without RESP3 support (5.0 and older).
- Properly reject empty commands early.

# 0.4.0

- The `hiredis` driver have been moved to the `hiredis-client` gem.

# 0.3.0

- `hiredis` is now the default driver when available.
- Add `RedisClient.default_driver=`.
- `#call` now takes an optional block to cast the return value.
- Treat `#call` keyword arguments as Redis flags.
- Fix `RedisClient#multi` returning some errors as values instead of raising them.

# 0.2.1

- Use a more robust way to detect the current compiler.

# 0.2.0
- Added `RedisClient.register` as a public instrumentation API.
- Fix `read_timeout=` and `write_timeout=` to apply even when the client or pool is already connected.
- Properly convert DNS resolution errors into `RedisClient::ConnectionError`. Previously it would raise `SocketError`

# 0.1.0

- Initial Release
