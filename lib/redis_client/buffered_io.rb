# frozen_string_literal: true

class RedisClient
  class BufferedIO
    EOL = "\r\n".b.freeze

    def initialize(io, read_timeout:, write_timeout:, chunk_size: 4096)
      @io = io
      @buffer = String.new(encoding: Encoding::BINARY)
      @chunk_size = chunk_size
      @read_timeout = read_timeout
      @write_timeout = write_timeout
      @blocking_reads = false
    end

    def with_timeout(new_timeout)
      previous_read_timeout = @read_timeout
      previous_blocking_reads = @blocking_reads

      if new_timeout
        @read_timeout = new_timeout
      else
        @blocking_reads = true
      end

      begin
        yield
      ensure
        @read_timeout = previous_read_timeout
        @blocking_reads = previous_blocking_reads
      end
    end

    def skip(offset)
      read(offset)
      nil
    end

    def write(string)
      total = remaining = string.bytesize
      loop do
        case bytes_written = @io.write_nonblock(string, exception: false)
        when Integer
          remaining -= bytes_written
          if remaining > 0
            string = string.byteslice(bytes_written..-1)
          else
            return total
          end
        when :wait_readable
          @io.to_io.wait_readable(@read_timeout) or raise ReadTimeoutError
        when :wait_writable
          @io.to_io.wait_writable(@write_timeout) or raise WriteTimeoutError
        when nil
          raise Errno::ECONNRESET
        else
          raise "Unexpected `write_nonblock` return: #{bytes.inspect}"
        end
      end
    end

    def getbyte
      ensure_remaining(1)
      byte = @buffer.ord
      @buffer.slice!(0, 1)
      byte
    end

    def gets(chomp: false)
      offset = 0
      fill_buffer(false) if @buffer.empty?
      until eol_index = @buffer.index(EOL, offset)
        offset = @buffer.bytesize - 1
        fill_buffer(false)
      end
      line = @buffer.slice!(0, eol_index + 2)
      line.chomp! if chomp
      line
    end

    def read(bytes)
      ensure_remaining(bytes)
      @buffer.slice!(0, bytes)
    end

    def close
      @io.close
    end

    private

    def ensure_remaining(bytes)
      needed = bytes - @buffer.bytesize
      if needed > 0
        fill_buffer(true, needed)
      end
    end

    def fill_buffer(strict, size = @chunk_size)
      remaining = size
      loop do
        bytes = @io.read_nonblock([remaining, @chunk_size].max, exception: false)
        case bytes
        when String
          @buffer << bytes
          remaining -= bytes.bytesize
          return if !strict || remaining <= 0
        when :wait_readable
          unless @io.to_io.wait_readable(@read_timeout)
            raise ReadTimeoutError unless @blocking_reads
          end
        when :wait_writable
          @io.to_io.wait_writable(@write_timeout) or raise WriteTimeoutError
        when nil
          raise Errno::ECONNRESET
        else
          raise "Unexpected `read_nonblock` return: #{bytes.inspect}"
        end
      end
    end
  end
end
