# frozen_string_literal: true

class RedisClient
  module Middlewares
    extend self

    def call(command, _config)
      yield command
    end
    alias_method :call_pipelined, :call
  end
end
