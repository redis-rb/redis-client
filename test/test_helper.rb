# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "redis-client"
require "toxiproxy"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

ToxiproxyServerHelper.shutdown unless ENV["REDIS_CLIENT_RESTART_SERVER"] == "0"
ToxiproxyServerHelper.spawn

unless ENV["CI"]
  RedisServerHelper.shutdown unless ENV["REDIS_CLIENT_RESTART_SERVER"] == "0"
  RedisServerHelper.spawn
end

Toxiproxy.host = ToxiproxyServerHelper.url
Toxiproxy.populate([
  {
    name: "redis",
    upstream: "localhost:#{RedisServerHelper::REAL_TCP_PORT}",
    listen: ":#{RedisServerHelper::TCP_PORT}",
  },
  {
    name: "redis_tls",
    upstream: "localhost:#{RedisServerHelper::REAL_TLS_PORT}",
    listen: ":#{RedisServerHelper::TLS_PORT}",
  },
])

require "minitest/autorun"

unless ENV["REDIS_CLIENT_RESTART_SERVER"] == "0"
  Minitest.after_run { ToxiproxyServerHelper.shutdown }
  Minitest.after_run { RedisServerHelper.shutdown }
end
