# frozen_string_literal: true

Megatest.config do |c|
  c.global_setup do
    ServerManager.kill_all
    $stderr.puts "Running test suite with driver: #{RedisClient.default_driver}"
  end

  c.job_setup do |_, index|
    Servers::TESTS.shutdown
    Servers::SENTINEL_TESTS.shutdown

    ServerManager.worker_index = index
    Toxiproxy.host = "http://#{Servers::HOST}:#{Servers::TOXIPROXY.port}"
    unless Servers.all.prepare
      puts "worker #{index} failed setup"
      exit(1)
    end
  end

  c.job_teardown do
    unless ENV["REDIS_CLIENT_RESTART_SERVER"] == "0"
      Servers.all.shutdown
    end
  end
end
