# frozen_string_literal: true

class RedisClient
  class BasicMiddleware
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def connect(_config, _retry_attempts = 0)
      yield
    end

    def call(command, _config, _retry_attempts = 0)
      yield command
    end
    alias_method :call_pipelined, :call
  end

  class Middlewares < BasicMiddleware
  end
end
