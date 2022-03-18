# frozen_string_literal: true

require_relative "setup"

redis_client = RedisClient.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT)
redis = Redis.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT, driver: :ruby)
hiredis = Redis.new(host: "localhost", port: RedisServerHelper::REAL_TCP_PORT, driver: :hiredis)

redis_client.call("SET", "key", "value")
redis_client.call("SET", "large", "value" * 10_000)
redis_client.call("LPUSH", "list", *1000.times.to_a)
redis_client.call("HMSET", "hash", *1000.times.to_a)

puts "=== small string ==="
Benchmark.ips do |x|
  x.report("redis-rb") { redis.get("key") }
  x.report("hiredis-rb") { hiredis.get("key") }
  x.report("redis-client") { redis_client.call("GET", "key") }
  x.compare!(order: :baseline)
end

puts "=== large string ==="
Benchmark.ips do |x|
  x.report("redis-rb") { redis.get("large") }
  x.report("hiredis-rb") { hiredis.get("large") }
  x.report("redis-client") { redis_client.call("GET", "large") }
  x.compare!(order: :baseline)
end

puts "=== large list ==="
Benchmark.ips do |x|
  x.report("redis-rb") { redis.lrange("list", 0, -1) }
  x.report("hiredis-rb") { hiredis.lrange("list", 0, -1) }
  x.report("redis-client") { redis_client.call("LRANGE", "list", 0, -1) }
  x.compare!(order: :baseline)
end

puts "=== large hash ==="
Benchmark.ips do |x|
  x.report("redis-rb") { redis.hgetall("hash") }
  x.report("hiredis-rb") { hiredis.hgetall("hash") }
  x.report("redis-client") { redis_client.call("HGETALL", "hash") }
  x.compare!(order: :baseline)
end
