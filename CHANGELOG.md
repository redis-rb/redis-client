# Unreleased

# 0.2.0
- Added `RedisClient.register` as a public instrumentation API.
- Fix `read_timeout=` and `write_timeout=` to apply even when the client or pool is already connected.
- Properly convert DNS resolution errors into `RedisClient::ConnectionError`. Previously it would raise `SocketError`

# 0.1.0

- Initial Release
