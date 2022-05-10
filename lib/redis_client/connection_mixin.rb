# frozen_string_literal: true

class RedisClient
  module ConnectionMixin
    def call(command, timeout)
      write(command)
      result = read(timeout)
      if result.is_a?(CommandError)
        result._set_command(command)
        raise result
      else
        result
      end
    end

    def call_pipelined(commands, timeouts)
      exception = nil

      size = commands.size
      results = Array.new(commands.size)
      write_multi(commands)

      size.times do |index|
        timeout = timeouts && timeouts[index]
        result = read(timeout)
        if result.is_a?(CommandError)
          result._set_command(commands[index])
          exception ||= result
        end
        results[index] = result
      end

      if exception
        raise exception
      else
        results
      end
    end
  end
end
