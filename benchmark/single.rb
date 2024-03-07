# frozen_string_literal: true

require_relative "setup"

driver = ENV.fetch("DRIVER", "ruby").to_sym
redis_client = RedisClient.new(host: "localhost", port: Servers::REDIS.real_port, driver: :ruby)
hiredis_client = RedisClient.new(host: "localhost", port: Servers::REDIS.real_port, driver: :hiredis)

redis_client.call("SET", "key", "value")
redis_client.call("SET", "large", "value" * 10_000)
redis_client.call("LPUSH", "list", *5.times.to_a)
redis_client.call("LPUSH", "large-list", *1000.times.to_a)
redis_client.call("HMSET", "hash", *8.times.to_a)
redis_client.call("HMSET", "large-hash", *1000.times.to_a)


require 'vernier'

Vernier.trace(out: "/tmp/redis-client.dump") do
  1000.times do
    redis_client.call("LRANGE", "large-list", 0, -1)
  end

  1000.times do
    redis_client.call("HGETALL", "large-hash")
  end
end

# benchmark("small string") do |x|
#   x.report("ruby") { redis_client.call("GET", "key") }
#   x.report("hiredis") { hiredis_client.call("GET", "key") }
# end
#
# benchmark("large string") do |x|
#   x.report("ruby") { redis_client.call("GET", "large").valid_encoding? }
#   x.report("hiredis") { hiredis_client.call("GET", "large").valid_encoding? }
# end
#
# benchmark("small list") do |x|
#   x.report("ruby") { redis_client.call("LRANGE", "list", 0, -1) }
#   x.report("hiredis") { hiredis_client.call("LRANGE", "list", 0, -1) }
# end
#
# benchmark("large list") do |x|
#   x.report("ruby") { redis_client.call("LRANGE", "large-list", 0, -1) }
#   x.report("hiredis") { hiredis_client.call("LRANGE", "large-list", 0, -1) }
# end

# benchmark("small hash") do |x|
#   x.report("ruby") { redis_client.call("HGETALL", "hash") }
#   x.report("hiredis") { hiredis_client.call("HGETALL", "hash") }
# end

benchmark("large hash") do |x|
  x.report("ruby") { redis_client.call("HGETALL", "large-hash") }
  x.report("hiredis") { hiredis_client.call("HGETALL", "large-hash") }
end
