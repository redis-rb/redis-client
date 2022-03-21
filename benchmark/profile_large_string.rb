# frozen_string_literal: true

require_relative "setup"
require "stackprof"

redis_client = RedisClient.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT)
redis_client.call("SET", "large", "value" * 10_000)

StackProf.run(out: "tmp/stackprof-large-string.dump", raw: true) do
  1_000.times do
    redis_client.call("GET", "large")
  end
end
