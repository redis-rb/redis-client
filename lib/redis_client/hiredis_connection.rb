# frozen_string_literal: true

require "redis_client/hiredis_connection.so"
require "redis_client/connection_mixin"

class RedisClient
  class HiredisConnection
    include ConnectionMixin

    class SSLContext
      def initialize(ca_file: nil, ca_path: nil, cert: nil, key: nil, hostname: nil)
        if (error = init(ca_file, ca_path, cert, key, hostname))
          raise error
        end
      end
    end

    def initialize(config, connect_timeout:, read_timeout:, write_timeout:)
      self.connect_timeout = connect_timeout
      self.read_timeout = read_timeout
      self.write_timeout = write_timeout

      if config.path
        connect_unix(config.path)
      else
        connect_tcp(config.host, config.port)
      end

      if config.ssl
        init_ssl(config.hiredis_ssl_context)
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
  end
end
