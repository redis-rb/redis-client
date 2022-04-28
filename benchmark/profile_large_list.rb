# frozen_string_literal: true

require_relative "setup"
require "stackprof"

driver = ENV.fetch("DRIVER", "ruby").to_sym
redis_client = RedisClient.new(host: "localhost", port: Servers::REDIS.real_port, driver: driver)
redis_client.call("LPUSH", "list", *1000.times.to_a)

StackProf.run(out: "tmp/stackprof-large-list.dump", raw: true) do
  1_000.times do
    redis_client.call("LRANGE", "list", 0, -1)
  end
end
