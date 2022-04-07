# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
$LOAD_PATH.unshift(File.expand_path("../test/support", __dir__))

require "redis"
require "redis-client"
require "redis_client/hiredis_connection"
require "servers"
require "benchmark/ips"

Servers::BENCHMARK.prepare
at_exit { Servers::BENCHMARK.shutdown }

class RedisBenchmark
  def initialize(x)
    @x = x
  end

  def report(name, &block)
    @x.report(name, &block)
  end
end

def benchmark(name)
  if $stdout.tty?
    puts "=== #{name} ==="
  else
    puts "### #{name}\n\n```"
  end

  Benchmark.ips do |x|
    yield RedisBenchmark.new(x)
    x.compare!(order: :baseline)
  end

  unless $stdout.tty?
    puts "```\n\n"
  end
end
