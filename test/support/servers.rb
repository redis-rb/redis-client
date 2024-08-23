# frozen_string_literal: true

require_relative "redis_builder"
require_relative "server_manager"

module Servers
  ROOT = Pathname.new(File.expand_path("../../", __dir__))
  platform = `echo $(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')`.strip
  CACHE_DIR = ROOT.join("tmp/cache", platform)

  HOST = "127.0.0.1"
  CERTS_PATH = ServerManager::ROOT.join("test/fixtures/certs")

  SENTINEL_CONF_PATH = ServerManager::ROOT.join("tmp/sentinel.conf")
  SENTINEL_NAME = "cache"

  DEFAULT_REDIS_VERSION = "7.0"

  class << self
    def build_redis
      redis_builder.install
    end

    def redis_server_bin
      redis_builder.bin_path
    end

    def redis_builder
      @redis_builder ||= RedisBuilder.new(ENV.fetch("REDIS", DEFAULT_REDIS_VERSION), ROOT.join("tmp").to_s)
    end

    attr_accessor :all

    def reset
      all.reset
    end
  end

  class RedisManager < ServerManager
    def spawn
      begin
        dir.join("dump.rdb").to_s
      rescue Errno::ENOENT
      end
      super
    end

    def socket_file
      dir.join("redis.sock").to_s
    end

    def command
      ROOT.join("tmp/redis-#{worker_index.to_i}").mkpath
      [
        Servers.redis_server_bin,
        "--unixsocket", socket_file,
        "--unixsocketperm", "700",
        "--port", real_port.to_s,
        "--tls-port", real_tls_port.to_s,
        "--tls-cert-file", CERTS_PATH.join("redis.crt").to_s,
        "--tls-key-file", CERTS_PATH.join("redis.key").to_s,
        "--tls-ca-cert-file", CERTS_PATH.join("ca.crt").to_s,
        "--save", "",
        "--appendonly", "no",
        "--dir", dir,
      ]
    end

    def dir
      ROOT.join("tmp/redis-#{worker_index.to_i}")
    end

    def tls_port
      port + 10_000
    end

    def real_tls_port
      real_port + 10_000
    end
  end

  REDIS = RedisManager.new(
    "redis",
    port: 16379,
    real_port: 16380,
  )

  class RedisReplicaManager < ServerManager
    def command
      [
        Servers.redis_server_bin,
        "--port", real_port.to_s,
        "--save", "",
        "--appendonly", "no",
        "--dir", "tmp/",
        "--replicaof", REDIS.host, REDIS.real_port.to_s,
      ]
    end
  end

  REDIS_REPLICA = RedisReplicaManager.new(
    "redis_replica",
    port: 16381,
    real_port: 16382,
  )

  REDIS_REPLICA_2 = RedisReplicaManager.new(
    "redis_replica_2",
    port: 16383,
    real_port: 16384,
  )

  class SentinelManager < ServerManager
    def generate_conf
      conf_file.write(<<~EOS)
        sentinel monitor #{SENTINEL_NAME} #{REDIS.host} #{REDIS.port} 2
        sentinel down-after-milliseconds #{SENTINEL_NAME} 10
        sentinel failover-timeout #{SENTINEL_NAME} 2000
        sentinel parallel-syncs #{SENTINEL_NAME} 1
        user alice on allcommands allkeys >superpassword
      EOS
    end

    def conf_file
      ROOT.join("tmp/#{name}-#{worker_index.to_i}.conf")
    end

    def command
      [
        Servers.redis_server_bin,
        conf_file.to_s,
        "--port", real_port.to_s,
        "--sentinel",
      ]
    end

    def spawn
      generate_conf
      super
    end
  end

  SENTINELS = [
    SentinelManager.new(
      "redis_sentinel_1",
      port: 26_300,
      real_port: 26_301,
      command: [],
    ),
    SentinelManager.new(
      "redis_sentinel_2",
      port: 26_302,
      real_port: 26_303,
      command: [],
    ),
    SentinelManager.new(
      "redis_sentinel_3",
      port: 26_304,
      real_port: 26_305,
      command: [],
    ),
  ].freeze

  class ToxiproxyManager < ServerManager
    BIN = CACHE_DIR.join("toxiproxy-server")

    def spawn
      system(ROOT.join("bin/install-toxiproxy").to_s) unless BIN.exist?
      super
    end

    def command
      [
        ToxiproxyManager::BIN.to_s,
        "-port",
        port.to_s,
      ]
    end

    def on_ready
      Toxiproxy.host = "http://#{host}:#{port}"

      retries = 3

      begin
        Toxiproxy.populate(proxies)
      rescue SystemCallError, Net::HTTPError, Net::ProtocolError
        retries -= 1
        if retries > 0
          sleep 0.5
          retry
        else
          raise
        end
      end
    end

    def proxies
      [
        {
          name: "redis",
          upstream: "localhost:#{REDIS.real_port}",
          listen: ":#{REDIS.port}",
        },
        {
          name: "redis_tls",
          upstream: "localhost:#{REDIS.real_tls_port}",
          listen: ":#{REDIS.tls_port}",
        },
        {
          name: "redis_replica",
          upstream: "localhost:#{REDIS_REPLICA.real_port}",
          listen: ":#{REDIS_REPLICA.port}",
        },
        {
          name: "redis_replica_2",
          upstream: "localhost:#{REDIS_REPLICA_2.real_port}",
          listen: ":#{REDIS_REPLICA_2.port}",
        },
      ]
    end
  end

  class ToxiproxySentinelManager < ToxiproxyManager
    def proxies
      sentinels = SENTINELS.map do |sentinel|
        {
          name: sentinel.name,
          upstream: "localhost:#{sentinel.real_port}",
          listen: ":#{sentinel.port}",
        }
      end
      super + sentinels
    end
  end

  TOXIPROXY = ToxiproxyManager.new(
    "toxiproxy",
    port: 8475,
    command: [],
  )

  TOXIPROXY_SENTINELS = ToxiproxySentinelManager.new(
    "toxiproxy",
    port: 8475,
    command: [],
  )

  TESTS = ServerList.new(
    TOXIPROXY,
    REDIS,
  )

  SENTINEL_TESTS = ServerList.new(
    TOXIPROXY_SENTINELS,
    REDIS,
    REDIS_REPLICA,
    REDIS_REPLICA_2,
    *SENTINELS,
  )

  BENCHMARK = ServerList.new(REDIS)
end
