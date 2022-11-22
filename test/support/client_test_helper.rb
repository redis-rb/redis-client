# frozen_string_literal: true

module ClientTestHelper
  module FlakyDriver
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :failures
    end

    def write(command)
      if self.class.failures.first == command.first
        self.class.failures.shift
        @fail_now = true
      end
      super
    end

    def read(*)
      @fail_now ||= false
      if @fail_now
        raise ::RedisClient::ConnectionError, "simulated failure"
      end

      super
    end

    def write_multi(commands)
      commands.each { |c| write(c) }
      nil
    end
  end

  def setup
    @redis = new_client
    @redis.call("FLUSHDB")
  end

  private

  def travel(seconds, &block)
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    Process.stub(:clock_gettime, now, &block)
  end

  def tcp_config
    {
      host: Servers::HOST,
      port: Servers::REDIS_TCP_PORT,
      timeout: 0.1,
    }
  end

  def ssl_config
    {
      host: Servers::HOST,
      port: Servers::REDIS_TLS_PORT,
      timeout: 0.1,
      ssl: true,
      ssl_params: {
        cert: Servers::CERTS_PATH.join("client.crt").to_s,
        key: Servers::CERTS_PATH.join("client.key").to_s,
        ca_file: Servers::CERTS_PATH.join("ca.crt").to_s,
      },
    }
  end

  def unix_config
    {
      path: Servers::REDIS_SOCKET_FILE.to_s,
      timeout: 0.1,
    }
  end

  def new_client(**overrides)
    RedisClient.new(**tcp_config.merge(overrides))
  end

  def simulate_network_errors(client, failures)
    client.close
    original_config = client.config
    flaky_driver = Class.new(original_config.driver)
    flaky_driver.include(FlakyDriver)
    flaky_driver.failures = failures
    flaky_config = original_config.dup
    flaky_config.instance_variable_set(:@driver, flaky_driver)
    begin
      client.instance_variable_set(:@config, flaky_config)
      yield
    ensure
      client.instance_variable_set(:@config, original_config)
    end
  end
end
