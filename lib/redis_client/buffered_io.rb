# frozen_string_literal: true

class RedisClient
  class BufferedIO
    EOL = "\r\n".b.freeze

    def initialize(io, read_timeout: 5, write_timeout: 5, chunk_size: 4096)
      @io = io
      @buffer = String.new(encoding: Encoding::BINARY)
      @chunk_size = chunk_size
      @read_timeout = read_timeout
      @write_timeout = write_timeout
    end

    def seek(offset, whence = IO::SEEK_SET)
      if whence != IO::SEEK_CUR
        raise NotImplementedError, "Only IO::SEEK_CUR is supported"
      end

      ensure_remaining(offset)
      @buffer.slice!(0, offset)
      0
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
          @io.wait_readable(@read_timeout) or raise ReadTimeoutError
        when :wait_writable
          @io.wait_writable(@write_timeout) or raise WriteTimeoutError
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
      until eol_index = @buffer.index(EOL, offset)
        offset = @buffer.bytesize
        fill_buffer
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
        fill_buffer(needed)
      end
    end

    def fill_buffer(size = @chunk_size)
      remaining = size
      loop do
        case bytes = @io.read_nonblock([remaining, @chunk_size].max, exception: false)
        when String
          @buffer << bytes
          remaining -= bytes.bytesize
          return if remaining < 0
        when :wait_readable
          @io.wait_readable(@read_timeout) or raise ReadTimeoutError
        when :wait_writable
          @io.wait_writable(@write_timeout) or raise WriteTimeoutError
        end
      end
    end
  end
end
