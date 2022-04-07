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
