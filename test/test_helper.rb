# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "redis-client"
require "toxiproxy"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

Servers.build_redis
Servers::ALL.prepare

require "minitest/autorun"

unless ENV["REDIS_CLIENT_RESTART_SERVER"] == "0"
  Minitest.after_run { Servers::ALL.shutdown }
end

if ENV["DRIVER"] == "hiredis"
  # See: https://github.com/redis-rb/redis-client/issues/16
  # The hiredis-rb gems expose all hiredis symbols, so we must be careful
  # about how we link against it.
  require "redis"
  require "hiredis"
  Redis.new(host: Servers::HOST, port: Servers::REDIS_TCP_PORT, driver: :hiredis).ping
end
