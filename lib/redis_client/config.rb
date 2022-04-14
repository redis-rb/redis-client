# frozen_string_literal: true

require "uri"

class RedisClient
  class Config
    DEFAULT_TIMEOUT = 1.0
    DEFAULT_HOST = "localhost"
    DEFAULT_PORT = 6379
    DEFAULT_USERNAME = "default"
    DEFAULT_DB = 0

    module Common
      attr_reader :db, :username, :password, :id, :ssl, :ssl_params,
        :connect_timeout, :read_timeout, :write_timeout, :driver, :connection_prelude

      alias_method :ssl?, :ssl

      def initialize(
        username: nil,
        password: nil,
        db: nil,
        id: nil,
        timeout: DEFAULT_TIMEOUT,
        read_timeout: timeout,
        write_timeout: timeout,
        connect_timeout: timeout,
        ssl: nil,
        ssl_params: nil,
        driver: :ruby,
        reconnect_attempts: false
      )
        @username = username || DEFAULT_USERNAME
        @password = password
        @db = db || DEFAULT_DB
        @id = id
        @ssl = ssl || false

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

        reconnect_attempts = Array.new(reconnect_attempts, 0).freeze if reconnect_attempts.is_a?(Integer)
        @reconnect_attempts = reconnect_attempts

        @connection_prelude = build_connection_prelude
      end

      def sentinel?
        false
      end

      def new_pool(**kwargs)
        kwargs[:timeout] ||= DEFAULT_TIMEOUT
        Pooled.new(self, **kwargs)
      end

      def new_client(**kwargs)
        RedisClient.new(self, **kwargs)
      end

      def retry_connecting?(attempt, _error)
        if @reconnect_attempts
          if (pause = @reconnect_attempts[attempt])
            if pause > 0
              sleep(pause)
            end
            return true
          end
        end
        false
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
          if context.verify_mode != OpenSSL::SSL::VERIFY_NONE
            if context.respond_to?(:verify_hostname) # Missing on JRuby
              context.verify_hostname
            end
          end
          context
        end
      end

      private

      def build_connection_prelude
        prelude = []
        prelude <<  if @password
          ["HELLO", "3", "AUTH", @username, @password]
        else
          ["HELLO", "3"]
        end

        if @db && @db != 0
          prelude << ["SELECT", @db.to_s]
        end
        prelude.freeze
      end
    end

    include Common

    attr_reader :host, :port, :path

    def initialize(
      url: nil,
      host: nil,
      port: nil,
      path: nil,
      **kwargs
    )
      uri = url && URI.parse(url)
      if uri
        kwargs[:ssl] = uri.scheme == "rediss" unless kwargs.key?(:ssl)

        kwargs[:username] ||= uri.user && uri.password

        kwargs[:password] ||= if uri.user && !uri.password
          URI.decode_www_form_component(uri.user)
        elsif uri&.user && uri&.password
          URI.decode_www_form_component(uri.password)
        end

        kwargs[:db] ||= Integer(uri.path.delete_prefix("/")) if uri.path && !uri.path.empty?
      end

      super(**kwargs)

      @host = host || uri&.host || DEFAULT_HOST
      @port = port || uri&.port || DEFAULT_PORT
      @path = path
    end
  end
end
