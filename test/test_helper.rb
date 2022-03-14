# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "redis-client"
require "toxiproxy"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

require "minitest/autorun"

unless ENV["CI"]
  RedisServerHelper.shutdown
  ToxiproxyServerHelper.shutdown
  ToxiproxyServerHelper.spawn
  RedisServerHelper.spawn
  Minitest.after_run { RedisServerHelper.shutdown }
  Minitest.after_run { ToxiproxyServerHelper.shutdown }
end

Toxiproxy.host = ToxiproxyServerHelper.url
redis_host = proxy_host = "localhost"
if ENV["CI"]
  redis_host = "redis"
  proxy_host = "toxiproxy"
end

Toxiproxy.populate([
  {
    name: "redis",
    upstream: "#{redis_host}:#{RedisServerHelper::REAL_TCP_PORT}",
    listen: "#{proxy_host}:#{RedisServerHelper::TCP_PORT}",
  },
  {
    name: "redis_tls",
    upstream: "#{redis_host}:#{RedisServerHelper::REAL_TLS_PORT}",
    listen: "#{proxy_host}:#{RedisServerHelper::TLS_PORT}",
  },
])
