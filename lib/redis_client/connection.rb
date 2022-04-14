# frozen_string_literal: true

require "socket"
require "openssl"
require "redis_client/buffered_io"

class RedisClient
  class Connection
    def initialize(config, connect_timeout:, read_timeout:, write_timeout:)
      socket = if config.path
        UNIXSocket.new(config.path)
      else
        sock = Socket.tcp(config.host, config.port, connect_timeout: connect_timeout)
        # disables Nagle's Algorithm, prevents multiple round trips with MULTI
        sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        sock
      end

      if config.ssl
        socket = OpenSSL::SSL::SSLSocket.new(socket, config.openssl_context)
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

      @io = BufferedIO.new(
        socket,
        read_timeout: read_timeout,
        write_timeout: write_timeout,
      )
    rescue Errno::ETIMEDOUT => error
      raise ConnectTimeoutError, error.message
    rescue SystemCallError, OpenSSL::SSL::SSLError => error
      raise ConnectionError, error.message
    end

    def connected?
      !@io.closed?
    end

    def close
      @io.close
    end

    def write(command)
      buffer = RESP3.dump(command)
      begin
        @io.write(buffer)
      rescue SystemCallError, IOError => error
        raise ConnectionError, error.message
      end
    end

    def write_multi(commands)
      buffer = nil
      commands.each do |command|
        buffer = RESP3.dump(command, buffer)
      end
      begin
        @io.write(buffer)
      rescue SystemCallError, IOError => error
        raise ConnectionError, error.message
      end
    end

    def read(timeout = nil)
      if timeout.nil?
        RESP3.load(@io)
      else
        @io.with_timeout(timeout) { RESP3.load(@io) }
      end
    rescue SystemCallError, IOError, OpenSSL::SSL::SSLError => error
      raise ConnectionError, error.message
    end
  end
end
