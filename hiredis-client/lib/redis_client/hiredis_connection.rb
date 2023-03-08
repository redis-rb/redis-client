# frozen_string_literal: true

require "openssl"
require "redis_client/hiredis_connection.so"
require "redis_client/connection_mixin"

class RedisClient
  class HiredisConnection
    include ConnectionMixin

    class << self
      def ssl_context(ssl_params)
        HiredisConnection::SSLContext.new(
          ca_file: ssl_params[:ca_file],
          ca_path: ssl_params[:ca_path],
          cert: ssl_params[:cert],
          key: ssl_params[:key],
          hostname: ssl_params[:hostname],
        )
      end
    end

    class SSLContext
      def initialize(ca_file: nil, ca_path: nil, cert: nil, key: nil, hostname: nil)
        if (error = init(ca_file, ca_path, cert, key, hostname))
          raise error
        end
      end
    end

    def initialize(config, connect_timeout:, read_timeout:, write_timeout:)
      super()
      @config = config
      self.connect_timeout = connect_timeout
      self.read_timeout = read_timeout
      self.write_timeout = write_timeout
      connect
    end

    def close
      _close
      super
    end

    def reconnect
      reconnected = begin
        _reconnect
      rescue SystemCallError => error
        if @config.path
          raise CannotConnectError, error.message, error.backtrace
        else
          error_code = error.class.name.split("::").last
          raise CannotConnectError, "Failed to connect to #{@config.host}:#{@config.port} (#{error_code})"
        end
      end

      if reconnected
        if @config.ssl
          return init_ssl(@config.ssl_context)
        end

        true
      else
        # Reusing the hiredis connection didn't work let's create a fresh one
        super
      end
    end

    def connect_timeout=(timeout)
      self.connect_timeout_us = timeout ? (timeout * 1_000_000).to_i : 0
      @connect_timeout = timeout
    end

    def read_timeout=(timeout)
      self.read_timeout_us = timeout ? (timeout * 1_000_000).to_i : 0
      @read_timeout = timeout
    end

    def write_timeout=(timeout)
      self.write_timeout_us = timeout ? (timeout * 1_000_000).to_i : 0
      @write_timeout = timeout
    end

    def read(timeout = nil)
      if timeout.nil?
        _read
      else
        previous_timeout = @read_timeout
        self.read_timeout = timeout
        begin
          _read
        ensure
          self.read_timeout = previous_timeout
        end
      end
    rescue SystemCallError, IOError => error
      raise ConnectionError, error.message
    end

    def write(command)
      _write(command)
      flush
    rescue SystemCallError, IOError => error
      raise ConnectionError, error.message
    end

    def write_multi(commands)
      commands.each do |command|
        _write(command)
      end
      flush
    rescue SystemCallError, IOError => error
      raise ConnectionError, error.message
    end

    private

    def connect
      if @config.path
        begin
          connect_unix(@config.path)
        rescue SystemCallError => error
          raise CannotConnectError, error.message, error.backtrace
        end
      else
        begin
          connect_tcp(@config.host, @config.port)
        rescue SystemCallError => error
          error_code = error.class.name.split("::").last
          raise CannotConnectError, "Failed to connect to #{@config.host}:#{@config.port} (#{error_code})"
        end
      end

      if @config.ssl
        init_ssl(@config.ssl_context)
      end
    end
  end
end
