# frozen_string_literal: true

require_relative "setup"
require "stackprof"

driver = ENV.fetch("DRIVER", "ruby").to_sym
redis_client = RedisClient.new(host: "localhost", port: Servers::REDIS.real_port, driver: driver)

StackProf.run(out: "tmp/stackprof-pipeline.dump", raw: true) do
  10_000.times do
    redis_client.pipelined do |pipeline|
      pipeline.call("SET", "foo", "bar")
      pipeline.call("GET", "foo")
      pipeline.call("INCRBY", "counter", 2)
    end
  end
end
