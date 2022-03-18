# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
$LOAD_PATH.unshift(File.expand_path("../test/support", __dir__))

require "redis"
require "redis-client"
require "redis_server_helper"
require "benchmark/ips"

RedisServerHelper.shutdown
RedisServerHelper.spawn
at_exit { RedisServerHelper.shutdown }
