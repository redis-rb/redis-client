# frozen_string_literal: true

require "socket"
require "openssl"
require "redis_client/connection_mixin"
require "redis_client/ruby_connection/buffered_io"
require "redis_client/ruby_connection/resp3"

class RedisClient
  class RubyConnection
    include ConnectionMixin

    class << self
      def ssl_context(ssl_params)
        params = ssl_params.dup || {}

        cert = params[:cert]
        if cert.is_a?(String)
          cert = File.read(cert) if File.exist?(cert)
          params[:cert] = OpenSSL::X509::Certificate.new(cert)
        end

        key = params[:key]
        if key.is_a?(String)
          key = File.read(key) if File.exist?(key)
          params[:key] = OpenSSL::PKey.read(key)
        end

        context = OpenSSL::SSL::SSLContext.new
        context.set_params(params)
        if context.verify_mode != OpenSSL::SSL::VERIFY_NONE
          if context.respond_to?(:verify_hostname) # Missing on JRuby
            context.verify_hostname
          end
        end

        context
      end
    end

    SUPPORTS_RESOLV_TIMEOUT = Socket.method(:tcp).parameters.any? { |p| p.last == :resolv_timeout }

    def initialize(config, connect_timeout:, read_timeout:, write_timeout:)
      super()
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
        socket = OpenSSL::SSL::SSLSocket.new(socket, config.ssl_context)
        socket.hostname = config.host
        loop do
          case status = socket.connect_nonblock(exception: false)
          when :wait_readable
            socket.to_io.wait_readable(connect_timeout) or raise CannotConnectError
          when :wait_writable
            socket.to_io.wait_writable(connect_timeout) or raise CannotConnectError
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
    rescue SystemCallError, OpenSSL::SSL::SSLError, SocketError => error
      raise CannotConnectError, error.message, error.backtrace
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
    rescue RedisClient::RESP3::UnknownType => error
      raise RedisClient::ProtocolError, error.message
    rescue SystemCallError, IOError, OpenSSL::SSL::SSLError => error
      raise ConnectionError, error.message
    end
  end
end
