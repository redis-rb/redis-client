# frozen_string_literal: true

require "uri"

class RedisClient
  class URLConfig
    DEFAULT_SCHEMA = "redis"
    SSL_SCHEMA = "rediss"

    attr_reader :url, :uri

    def initialize(url)
      @url = url
      @uri = URI(url)
      unless uri.scheme == DEFAULT_SCHEMA || uri.scheme == SSL_SCHEMA
        raise ArgumentError, "Invalid URL: #{url.inspect}"
      end
    end

    def ssl?
      @uri.scheme == SSL_SCHEMA
    end

    def db
      db_path = uri.path&.delete_prefix("/")
      Integer(db_path) if db_path && !db_path.empty?
    end

    def username
      uri.user if uri.password && !uri.user.empty?
    end

    def password
      if uri.user && !uri.password
        URI.decode_www_form_component(uri.user)
      elsif uri.user && uri.password
        URI.decode_www_form_component(uri.password)
      end
    end

    def host
      return if uri.host.nil? || uri.host.empty?

      uri.host.sub(/\A\[(.*)\]\z/, '\1')
    end

    def port
      return unless uri.port

      Integer(uri.port)
    end
  end
end
