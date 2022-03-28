# frozen_string_literal: true

require "uri"

class RedisClient
  class Config
    DEFAULT_TIMEOUT = 3
    DEFAULT_HOST = "localhost"
    DEFAULT_PORT = 6379
    DEFAULT_USERNAME = "default"
    DEFAULT_DB = 0
    DEFAULT_RECONNECT_ATTEMPTS = [0].freeze

    attr_reader :host, :port, :db, :username, :password, :id, :ssl, :ssl_params, :path,
      :connect_timeout, :read_timeout, :write_timeout, :driver

    alias_method :ssl?, :ssl

    def initialize(
      url: nil,
      host: nil,
      port: nil,
      path: nil,
      username: nil,
      password: nil,
      db: nil,
      id: nil,
      timeout: DEFAULT_TIMEOUT,
      read_timeout: timeout,
      write_timeout: timeout,
      connect_timeout: timeout,
      reconnect_attempts: DEFAULT_RECONNECT_ATTEMPTS,
      ssl: nil,
      ssl_params: nil,
      middlewares: [],
      driver: :ruby
    )
      uri = url && URI.parse(url)

      @host = host || uri&.host || DEFAULT_HOST
      @port = port || uri&.port || DEFAULT_PORT
      @path = path

      @username = if username
        username
      elsif uri&.user && uri&.password
        uri.user
      else
        DEFAULT_USERNAME
      end

      @password = if password
        password
      elsif uri&.user && !uri.password
        URI.decode_www_form_component(uri.user)
      elsif uri&.user && uri&.password
        URI.decode_www_form_component(uri.password)
      end

      @db = if db
        db
      elsif uri&.path && !uri.path.empty?
        Integer(uri.path.delete_prefix("/"))
      else
        DEFAULT_DB
      end

      @id = id
      @ssl = if !ssl.nil?
        ssl
      elsif uri
        uri.scheme == "rediss"
      else
        false
      end

      @ssl_params = ssl_params
      @connect_timeout = connect_timeout
      @read_timeout = read_timeout
      @write_timeout = write_timeout

      @driver = case driver
      when :ruby
        Connection
      when :hiredis
        unless defined?(RedisClient::HiredisConnection)
          require "redis_client/hiredis_connection"
        end
        HiredisConnection
      else
        raise ArgumentError, "Unknown driver #{driver.inspect}, expected one of: `:ruby`, `:hiredis`"
      end

      if reconnect_attempts
        middlewares << ReconnectMiddleware.new(reconnect_attempts)
      end

      @middlewares = unless middlewares.empty?
        middlewares.reverse.inject(FinalMiddleware) { |memo, middleware| middleware.new(memo, self) }
      end
    end

    def new_client(**kwargs)
      RedisClient.new(self, **kwargs)
    end

    def hiredis_ssl_context
      @hiredis_ssl_context ||= HiredisConnection::SSLContext.new(
        ca_file: @ssl_params[:ca_file],
        ca_path: @ssl_params[:ca_path],
        cert: @ssl_params[:cert],
        key: @ssl_params[:key],
        hostname: @ssl_params[:hostname],
      )
    end

    def openssl_context
      @openssl_context ||= begin
        params = @ssl_params.dup || {}

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
        context
      end
    end

    module FinalMiddleware
      extend self

      def call(command)
        yield command
      end
      alias_method :call_pipelined, :call
    end

    def around_call(command, &block)
      if @middlewares
        @middlewares.call(command, &block)
      else
        yield command
      end
    end

    def around_call_pipelined(commands, &block)
      if @middlewares
        @middlewares.call_pipelined(commands, &block)
      else
        yield commands
      end
    end
  end
end
