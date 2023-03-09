# frozen_string_literal: true

class RedisClient
  module ConnectionMixin
    def initialize
      @pending_reads = 0
    end

    def reconnect
      close
      connect
    end

    def close
      @pending_reads = 0
      nil
    end

    def revalidate
      if @pending_reads > 0
        close
        false
      else
        connected?
      end
    end

    def call(command, timeout)
      @pending_reads += 1
      write(command)
      result = read(timeout)
      @pending_reads -= 1
      if result.is_a?(Error)
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
      @pending_reads += size
      write_multi(commands)

      size.times do |index|
        timeout = timeouts && timeouts[index]
        result = read(timeout)
        @pending_reads -= 1
        if result.is_a?(Error)
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
