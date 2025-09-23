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
        raise connection_error("simulated failure")
      end

      super
    end

    def reconnect
      @fail_now = false
      super
    end

    def write_multi(commands)
      commands.each { |c| write(c) }
      nil
    end
  end

  def setup
    super

    @redis = new_client
    check_server
  end

  private

  def check_server
    retried = false
    begin
      @redis.call("flushdb", "async")
    rescue
      if retried
        raise
      else
        retried = true
        Servers.reset
        retry
      end
    end
  end

  def travel(seconds)
    original_now = RedisClient.singleton_class.instance_method(:now)
    original_now_ms = RedisClient.singleton_class.instance_method(:now_ms)
    begin
      RedisClient.singleton_class.alias_method(:now, :now)
      RedisClient.define_singleton_method(:now) do
        original_now.bind(RedisClient).call + seconds
      end

      RedisClient.singleton_class.alias_method(:now_ms, :now_ms)
      RedisClient.define_singleton_method(:now_ms) do
        original_now_ms.bind(RedisClient).call + (seconds * 1000.0)
      end

      yield
    ensure
      RedisClient.singleton_class.alias_method(:now, :now)
      RedisClient.define_singleton_method(:now, original_now)
      RedisClient.singleton_class.alias_method(:now_ms, :now_ms)
      RedisClient.define_singleton_method(:now_ms, original_now_ms)
    end
  end

  def simulate_network_errors(client, failures)
    client.close
    client.instance_variable_set(:@raw_connection, nil)

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
      client.close
      client.instance_variable_set(:@raw_connection, nil)
    end
  end

  module_function

  DEFAULT_TIMEOUT = 0.1

  def tcp_config
    {
      host: Servers::HOST,
      port: Servers::REDIS.port,
      timeout: DEFAULT_TIMEOUT,
    }
  end

  def ssl_config
    {
      host: Servers::HOST,
      port: Servers::REDIS.tls_port,
      timeout: DEFAULT_TIMEOUT,
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
      path: Servers::REDIS.socket_file.to_s,
      timeout: DEFAULT_TIMEOUT,
    }
  end

  def new_client(**overrides)
    RedisClient.new(**tcp_config.merge(overrides))
  end
end
