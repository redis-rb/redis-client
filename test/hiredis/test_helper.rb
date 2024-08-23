# frozen_string_literal: true

require_relative "../test_helper"

# See: https://github.com/redis-rb/redis-client/issues/16
# The hiredis-rb gems expose all hiredis symbols, so we must be careful
# about how we link against it.
unless RUBY_PLATFORM == "java"
  require "redis"
  require "hiredis"

  begin
    Redis.new(driver: :hiredis).ping
  rescue
    nil # does not matter, we just want to load the library
  end
end

require "hiredis-client"

unless RedisClient.default_driver == RedisClient::HiredisConnection
  abort("Hiredis not defined as default driver")
end

begin
  # This method was added in Ruby 3.0.0. Calling it this way asks the GC to
  # move objects around, helping to find object movement bugs.
  if RUBY_VERSION >= "3.2.0"
    GC.verify_compaction_references(expand_heap: true, toward: :empty)
  else
    GC.verify_compaction_references(double_heap: true, toward: :empty)
  end
rescue NoMethodError
end
