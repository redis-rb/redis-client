# frozen_string_literal: true

class RedisClient
  class Middleware
    def initialize
      @client = nil
      @config = nil
    end

    def new(client, config)
      copy = dup
      copy.client = client
      copy.config = config
      copy
    end

    protected

    attr_writer :client, :config
  end

  class ReconnectMiddleware < Middleware
    def initialize(attempts)
      super()
      attempts = Array.new(reconnect_attempts, 0) if attempts.is_a?(Integer)
      @attempts = attempts
    end

    def call(command, &block)
      tries = 0
      begin
        @client.call(command, &block)
      rescue ConnectionError
        wait_time = @attempts[tries]
        raise if wait_time.nil?

        sleep(wait_time) if wait_time > 0
        tries += 1
        retry
      end
    end

    def call_pipelined(commands, &block)
      tries = 0
      begin
        @client.call_pipelined(commands, &block)
      rescue ConnectionError
        wait_time = @attempts[tries]
        raise if wait_time.nil?

        sleep(wait_time) if wait_time > 0
        tries += 1
        retry
      end
    end
  end
end
