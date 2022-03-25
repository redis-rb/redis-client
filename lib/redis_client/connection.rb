# frozen_string_literal: true

require "socket"
require "openssl"
require "redis_client/buffered_io"

class RedisClient
  class Connection
    class << self
      def create(config, connect_timeout:, read_timeout:, write_timeout:)
        socket = if config.path
          UNIXSocket.new(config.path)
        else
          sock = Socket.tcp(config.host, config.port, connect_timeout: connect_timeout)
          # disables Nagle's Algorithm, prevents multiple round trips with MULTI
          sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
          sock
        end

        if config.ssl
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.set_params(config.ssl_params || {})
          socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
          socket.hostname = config.host
          loop do
            case status = socket.connect_nonblock(exception: false)
            when :wait_readable
              socket.to_io.wait_readable(connect_timeout) or raise ReadTimeoutError
            when :wait_writable
              socket.to_io.wait_writable(connect_timeout) or raise WriteTimeoutError
            when socket
              break
            else
              raise "Unexpected `connect_nonblock` return: #{status.inspect}"
            end
          end
        end

        new(BufferedIO.new(
          socket,
          read_timeout: read_timeout,
          write_timeout: write_timeout,
        ))
      rescue Errno::ETIMEDOUT => error
        raise ConnectTimeoutError, error.message
      rescue SystemCallError => error
        raise ConnectionError, error.message
      end
    end

    def initialize(buffered_io)
      @io = buffered_io
    end

    def close
      @io.close
    end

    def write(command)
      @io.write(RESP3.dump(command))
    end

    def write_multi(commands)
      buffer = nil
      commands.each do |command|
        buffer = RESP3.dump(command, buffer)
      end
      @io.write(buffer)
    end

    def read(timeout = nil)
      if timeout.nil?
        RESP3.load(@io)
      else
        @io.with_timeout(timeout) { RESP3.load(@io) }
      end
    end
  end
end
