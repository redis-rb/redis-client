# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "redis-client"
require "toxiproxy"

Dir[File.join(__dir__, "../support/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "../shared/**/*.rb")].sort.each { |f| require f }

Servers.build_redis
Servers::SENTINEL_TESTS.prepare

require "minitest/autorun"
