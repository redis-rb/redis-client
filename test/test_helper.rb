# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "redis-client"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

require "minitest/autorun"

unless ENV["CI"]
  RedisServerHelper.shutdown
  RedisServerHelper.spawn
  Minitest.after_run { RedisServerHelper.shutdown }
  RedisServerHelper.wait_until_ready
end
