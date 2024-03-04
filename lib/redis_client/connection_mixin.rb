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
        result._set_config(config)
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

        # A multi/exec command can return an array of results.
        # An error from a multi/exec command is handled in Multi#_coerce!.
        if result.is_a?(Array)
          result.each do |res|
            res._set_config(config) if res.is_a?(Error)
          end
        elsif result.is_a?(Error)
          result._set_command(commands[index])
          result._set_config(config)
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
