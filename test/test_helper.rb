# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "redis-client"
require "redis_client/decorator"
require "toxiproxy"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "shared/**/*.rb")].sort.each { |f| require f }

Servers.build_redis
Servers::TESTS.prepare

require "minitest/autorun"

unless ENV["REDIS_CLIENT_RESTART_SERVER"] == "0"
  Minitest.after_run { Servers::TESTS.shutdown }
end

if ENV["DRIVER"] == "hiredis"
  # See: https://github.com/redis-rb/redis-client/issues/16
  # The hiredis-rb gems expose all hiredis symbols, so we must be careful
  # about how we link against it.
  require "redis"
  require "hiredis"
  Redis.new(host: Servers::HOST, port: Servers::REDIS_TCP_PORT, driver: :hiredis).ping
end

begin
  # This method was added in Ruby 3.0.0. Calling it this way asks the GC to
  # move objects around, helping to find object movement bugs.
  GC.verify_compaction_references(double_heap: true, toward: :empty)
rescue NoMethodError
end
