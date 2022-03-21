# frozen_string_literal: true

require_relative "setup"

redis_client = RedisClient.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT)
redis = Redis.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT, driver: :ruby)
hiredis = Redis.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT, driver: :hiredis)

redis_client.call("SET", "key", "value")
redis_client.call("SET", "large", "value" * 10_000)
redis_client.call("LPUSH", "list", *5.times.to_a)
redis_client.call("LPUSH", "large-list", *1000.times.to_a)
redis_client.call("HMSET", "hash", *8.times.to_a)
redis_client.call("HMSET", "large-hash", *1000.times.to_a)

benchmark("small string") do |x|
  x.report("redis-rb") { redis.get("key") }
  x.report("hiredis-rb") { hiredis.get("key") }
  x.report("redis-client") { redis_client.call("GET", "key") }
end

benchmark("large string") do |x|
  x.report("redis-rb") { redis.get("large") }
  x.report("hiredis-rb") { hiredis.get("large") }
  x.report("redis-client") { redis_client.call("GET", "large") }
end

benchmark("small list") do |x|
  x.report("redis-rb") { redis.lrange("list", 0, -1) }
  x.report("hiredis-rb") { hiredis.lrange("list", 0, -1) }
  x.report("redis-client") { redis_client.call("LRANGE", "list", 0, -1) }
end

benchmark("large list") do |x|
  x.report("redis-rb") { redis.lrange("large-list", 0, -1) }
  x.report("hiredis-rb") { hiredis.lrange("large-list", 0, -1) }
  x.report("redis-client") { redis_client.call("LRANGE", "large-list", 0, -1) }
end

benchmark("small hash") do |x|
  x.report("redis-rb") { redis.hgetall("hash") }
  x.report("hiredis-rb") { hiredis.hgetall("hash") }
  x.report("redis-client") { redis_client.call("HGETALL", "hash") }
end

benchmark("large hash") do |x|
  x.report("redis-rb") { redis.hgetall("large-hash") }
  x.report("hiredis-rb") { hiredis.hgetall("large-hash") }
  x.report("redis-client") { redis_client.call("HGETALL", "large-hash") }
end
