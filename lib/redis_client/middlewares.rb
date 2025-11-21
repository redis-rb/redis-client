# frozen_string_literal: true

class RedisClient
  class BasicMiddleware
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def connect(_config)
      yield
    end

    def call(command, _config)
      yield command
    end
    alias_method :call_pipelined, :call

    # These helpers keep backward compatibility with two-argument middlewares
    # while allowing newer ones to accept a third `context` parameter.
    def connect_with_context(config, context = nil, &block)
      invoke_with_optional_context(:connect, [config], context, &block)
    end

    def call_with_context(command, config, context = nil, &block)
      invoke_with_optional_context(:call, [command, config], context, &block)
    end

    def call_pipelined_with_context(commands, config, context = nil, &block)
      invoke_with_optional_context(:call_pipelined, [commands, config], context, &block)
    end

    private

    def invoke_with_optional_context(method_name, args, context, &block)
      method_obj = method(method_name)
      if context && accepts_extra_positional_arg?(method_obj, args.length)
        method_obj.call(*args, context, &block)
      else
        method_obj.call(*args, &block)
      end
    end

    def accepts_extra_positional_arg?(method_obj, required_args)
      parameters = method_obj.parameters
      return true if parameters.any? { |type, _| type == :rest }

      positional_count = parameters.count { |type, _| type == :req || type == :opt }
      positional_count >= (required_args + 1)
    end
  end

  class Middlewares < BasicMiddleware
  end
end
