# frozen_string_literal: true

require "uri"

class RedisClient
  class Config
    DEFAULT_TIMEOUT = 3
    DEFAULT_HOST = "localhost"
    DEFAULT_PORT = 6379
    DEFAULT_USERNAME = "default"
    DEFAULT_DB = 0

    attr_reader :host, :port, :db, :username, :password, :id, :ssl, :ssl_params, :path,
      :connect_timeout, :read_timeout, :write_timeout

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
      ssl: nil,
      ssl_params: nil
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
    end

    def new_client(**kwargs)
      RedisClient.new(self, **kwargs)
    end
  end
end
