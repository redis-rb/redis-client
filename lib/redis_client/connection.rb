# frozen_string_literal: true

require "socket"
require "openssl"
require "redis_client/buffered_io"

class RedisClient
  class Connection
    module Common
      def call(command, timeout)
        write(command)
        result = read(timeout)
        if result.is_a?(CommandError)
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

    include Common

    SUPPORTS_RESOLV_TIMEOUT = Socket.method(:tcp).parameters.any? { |p| p.last == :resolv_timeout }

    def initialize(config, connect_timeout:, read_timeout:, write_timeout:)
      socket = if config.path
        UNIXSocket.new(config.path)
      else
        sock = if SUPPORTS_RESOLV_TIMEOUT
          Socket.tcp(config.host, config.port, connect_timeout: connect_timeout, resolv_timeout: connect_timeout)
        else
          Socket.tcp(config.host, config.port, connect_timeout: connect_timeout)
        end
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
    rescue SystemCallError, OpenSSL::SSL::SSLError, SocketError => error
      raise ConnectionError, error.message
    end

    def connected?
      !@io.closed?
    end

    def close
      @io.close
    end

    def read_timeout=(timeout)
      @io.read_timeout = timeout if @io
    end

    def write_timeout=(timeout)
      @io.write_timeout = timeout if @io
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
