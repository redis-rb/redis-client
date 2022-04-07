# frozen_string_literal: true

class RedisClient
  class SentinelConfig
    include Config::Common

    SENTINEL_DELAY = 0.25
    DEFAULT_RECONNECT_ATTEMPTS = 2

    def initialize(name:, sentinels:, role: :master, **client_config)
      unless %i(master replica slave).include?(role)
        raise ArgumentError, "Expected role to be either :master or :replica, got: #{role.inspect}"
      end

      @name = name
      @sentinel_configs = sentinels.map { |s| Config.new(**s) }
      @sentinels = {}.compare_by_identity
      @role = role
      @mutex = Mutex.new
      @config = nil

      client_config[:reconnect_attempts] ||= DEFAULT_RECONNECT_ATTEMPTS
      @client_config = client_config || {}
      super(**client_config)
    end

    def sentinels
      @mutex.synchronize do
        @sentinel_configs.dup
      end
    end

    def reset
      @mutex.synchronize do
        @config = nil
      end
    end

    def host
      config.host
    end

    def port
      config.port
    end

    def path
      nil
    end

    def retry_connecting?(attempt, error)
      reset unless error.is_a?(TimeoutError)
      super
    end

    def sentinel?
      true
    end

    def check_role!(role)
      if @role == :master
        unless role == "master"
          sleep SENTINEL_DELAY
          raise FailoverError, "Expected to connect to a master, but the server is a replica"
        end
      else
        unless role == "slave"
          sleep SENTINEL_DELAY
          raise FailoverError, "Expected to connect to a replica, but the server is a master"
        end
      end
    end

    private

    def config
      @mutex.synchronize do
        @config ||= if @role == :master
          resolve_master
        else
          resolve_replica
        end
      end
    end

    def resolve_master
      each_sentinel do |sentinel_client|
        host, port = sentinel_client.call("SENTINEL", "get-master-addr-by-name", @name)
        if host && port
          return Config.new(host: host, port: Integer(port), **@client_config)
        end
      end
      raise ConnectionError, "Couldn't locate a master for role: #{@name}"
    end

    def sentinel_client(sentinel_config)
      @sentinels[sentinel_config] ||= sentinel_config.new_client
    end

    def resolve_replica
      each_sentinel do |sentinel_client|
        replicas = sentinel_client.call("SENTINEL", "replicas", @name)
        next if replicas.empty?

        replica = replicas.reject { |r| r["flags"].to_s.split(",").include?("disconnected") }.sample
        replica ||= replicas.sample
        return Config.new(host: replica["ip"], port: Integer(replica["port"]), **@client_config)
      end
      raise ConnectionError, "Couldn't locate a replica for role: #{@name}"
    end

    def each_sentinel
      last_error = nil

      @sentinel_configs.dup.each do |sentinel_config|
        sentinel_client = sentinel_client(sentinel_config)
        success = true
        begin
          yield sentinel_client
        rescue RedisClient::Error => error
          last_error = error
          success = false
          sleep SENTINEL_DELAY
        ensure
          if success
            @sentinel_configs.unshift(@sentinel_configs.delete(sentinel_config))
          end
        end
      end

      raise last_error if last_error
    end
  end
end
