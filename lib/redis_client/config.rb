# frozen_string_literal: true

require "openssl"
require "uri"

class RedisClient
  class Config
    DEFAULT_TIMEOUT = 1.0
    DEFAULT_HOST = "localhost"
    DEFAULT_PORT = 6379
    DEFAULT_USERNAME = "default"
    DEFAULT_DB = 0

    module Common
      attr_reader :db, :password, :id, :ssl, :ssl_params, :command_builder, :inherit_socket,
        :connect_timeout, :read_timeout, :write_timeout, :driver, :connection_prelude, :protocol,
        :middlewares

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
        driver: nil,
        protocol: 3,
        client_implementation: RedisClient,
        command_builder: CommandBuilder,
        inherit_socket: false,
        reconnect_attempts: false,
        middleware: nil
      )
        @username = username
        @password = password
        @db = db || DEFAULT_DB
        @id = id
        @ssl = ssl || false

        @ssl_params = ssl_params
        @connect_timeout = connect_timeout
        @read_timeout = read_timeout
        @write_timeout = write_timeout

        @driver = driver ? RedisClient.driver(driver) : RedisClient.default_driver

        @client_implementation = client_implementation
        @protocol = protocol
        unless protocol == 2 || protocol == 3
          raise ArgumentError, "Unknown protocol version #{protocol.inspect}, expected 2 or 3"
        end

        @command_builder = command_builder
        @inherit_socket = inherit_socket

        reconnect_attempts = Array.new(reconnect_attempts, 0).freeze if reconnect_attempts.is_a?(Integer)
        @reconnect_attempts = reconnect_attempts
        @connection_prelude = build_connection_prelude

        @middlewares = []
        Array(middleware).tap(&:compact!).each { |mw| register(mw) }
      end

      def username
        @username || DEFAULT_USERNAME
      end

      def sentinel?
        false
      end

      def new_pool(**kwargs)
        kwargs[:timeout] ||= DEFAULT_TIMEOUT
        Pooled.new(self, **kwargs)
      end

      def new_client(**kwargs)
        @client_implementation.new(self, **kwargs)
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

      def ssl_context
        @ssl_context ||= @driver.ssl_context(@ssl_params || {})
      end

      def server_url
        if path
          "#{path}/#{db}"
        else
          "redis#{'s' if ssl?}://#{host}:#{port}/#{db}"
        end
      end

      def register(middleware)
        @middlewares << RedisClient::Middlewares.dup.extend(middleware)
      end

      private

      def build_connection_prelude
        prelude = []
        if protocol == 3
          prelude << if @password
            ["HELLO", "3", "AUTH", @username || DEFAULT_USERNAME, @password]
          else
            ["HELLO", "3"]
          end
        elsif @password
          prelude << if @username && !@username.empty?
            ["AUTH", @username, @password]
          else
            ["AUTH", @password]
          end
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
      if url
        uri = URI.parse(url)
        kwargs[:ssl] = uri.scheme == "rediss" unless kwargs.key?(:ssl)

        kwargs[:username] ||= uri.user if uri.password && !uri.user.empty?

        kwargs[:password] ||= if uri.user && !uri.password
          URI.decode_www_form_component(uri.user)
        elsif uri.user && uri.password
          URI.decode_www_form_component(uri.password)
        end

        db_path = uri.path&.delete_prefix("/")
        kwargs[:db] ||= Integer(db_path) if db_path && !db_path.empty?
      end

      super(**kwargs)

      @host = host || uri&.host&.sub(/\A\[(.*)\]\z/, '\1') || DEFAULT_HOST
      @port = Integer(port || uri&.port || DEFAULT_PORT)
      @path = path
    end
  end
end
