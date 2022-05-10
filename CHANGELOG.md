# Unreleased

- Add `CommandError#command` to expose the command that caused the error.

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
