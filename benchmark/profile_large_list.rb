# frozen_string_literal: true

require_relative "setup"
require "stackprof"

redis_client = RedisClient.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT)
redis_client.call("LPUSH", "list", *1000.times.to_a)

StackProf.run(out: "tmp/stackprof-large-list.dump", raw: true) do
  1_000.times do
    redis_client.call("LRANGE", "list", 0, -1)
  end
end
