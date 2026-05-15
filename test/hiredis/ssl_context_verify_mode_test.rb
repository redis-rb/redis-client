# frozen_string_literal: true

require_relative "test_helper"

class HiredisSSLContextVerifyModeTest < RedisClientTestCase
  # `RedisClient::HiredisConnection::SSLContext` now accepts an optional
  # `verify_mode:` keyword. The integer is forwarded to the C extension
  # which calls `SSL_CTX_set_verify` on the underlying OpenSSL context,
  # mirroring `redisSSLOptions.verify_mode` from upstream hiredis.

  def test_default_verify_mode_is_unchanged
    # Backward-compatible: not passing verify_mode keeps hiredis'
    # default behavior (REDIS_SSL_VERIFY_PEER).
    ctx = RedisClient::HiredisConnection::SSLContext.new(
      ca_file: nil, ca_path: nil, cert: nil, key: nil, hostname: nil,
    )
    assert_kind_of(RedisClient::HiredisConnection::SSLContext, ctx)
  end

  def test_accepts_verify_none_to_bypass_peer_verification
    ctx = RedisClient::HiredisConnection::SSLContext.new(
      ca_file: nil, ca_path: nil, cert: nil, key: nil, hostname: nil,
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    )
    assert_kind_of(RedisClient::HiredisConnection::SSLContext, ctx)
  end

  def test_accepts_verify_peer
    ctx = RedisClient::HiredisConnection::SSLContext.new(
      ca_file: nil, ca_path: nil, cert: nil, key: nil, hostname: nil,
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
    )
    assert_kind_of(RedisClient::HiredisConnection::SSLContext, ctx)
  end

  def test_factory_forwards_verify_mode_from_ssl_params
    ssl_params = {
      ca_file: nil, ca_path: nil, cert: nil, key: nil, hostname: nil,
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }
    ctx = RedisClient::HiredisConnection.ssl_context(ssl_params)
    assert_kind_of(RedisClient::HiredisConnection::SSLContext, ctx)
  end

  def test_rejects_non_integer_verify_mode
    assert_raises(TypeError) do
      RedisClient::HiredisConnection::SSLContext.new(
        ca_file: nil, ca_path: nil, cert: nil, key: nil, hostname: nil,
        verify_mode: "none",
      )
    end
  end
end

