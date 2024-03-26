# frozen_string_literal: true

require_relative "setup"

ruby = RedisClient.new(host: "localhost", port: Servers::REDIS.real_port, driver: :ruby)
hiredis = RedisClient.new(host: "localhost", port: Servers::REDIS.real_port, driver: :hiredis)

ruby.call("SET", "key", "value")
ruby.call("SET", "large", "value" * 10_000)
ruby.call("LPUSH", "list", *5.times.to_a)
ruby.call("LPUSH", "large-list", *1000.times.to_a)
ruby.call("HMSET", "hash", *8.times.to_a)
ruby.call("HMSET", "large-hash", *1000.times.to_a)

benchmark("small string x 100") do |x|
  x.report("hiredis") { hiredis.pipelined { |p| 100.times { p.call("GET", "key") } } }
  x.report("ruby") { ruby.pipelined { |p| 100.times { p.call("GET", "key") } } }
end

benchmark("large string") do |x|
  x.report("hiredis") { hiredis.call("GET", "large") }
  x.report("ruby") { ruby.call("GET", "large") }
end

benchmark("small list x 100") do |x|
  x.report("hiredis") { hiredis.pipelined { |p| 100.times { p.call("LRANGE", "list", 0, -1) } } }
  x.report("ruby") { ruby.pipelined { |p| 100.times { p.call("LRANGE", "list", 0, -1) } } }
end

benchmark("large list") do |x|
  x.report("hiredis") { hiredis.call("LRANGE", "large-list", 0, -1) }
  x.report("ruby") { ruby.call("LRANGE", "large-list", 0, -1) }
end

benchmark("small hash x 100") do |x|
  x.report("hiredis") { hiredis.pipelined { |p| 100.times { p.call("HGETALL", "hash") } } }
  x.report("ruby") { ruby.pipelined { |p| 100.times { p.call("HGETALL", "hash") } } }
end

benchmark("large hash") do |x|
  x.report("hiredis") { ruby.call("HGETALL", "large-hash") }
  x.report("ruby") { ruby.call("HGETALL", "large-hash") }
end
