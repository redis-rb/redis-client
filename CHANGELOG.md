# Unreleased

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
