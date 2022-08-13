# frozen_string_literal: true

require_relative "redis_builder"
require_relative "server_manager"

module Servers
  ROOT = Pathname.new(File.expand_path("../../", __dir__))
  platform = `echo $(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')`.strip
  CACHE_DIR = ROOT.join("tmp/cache", platform)

  HOST = "127.0.0.1"
  CERTS_PATH = ServerManager::ROOT.join("test/fixtures/certs")

  REDIS_TCP_PORT = 16379
  REDIS_TLS_PORT = 26379
  REDIS_REAL_TCP_PORT = 16380
  REDIS_REAL_TLS_PORT = 26380
  REDIS_SOCKET_FILE = ServerManager::ROOT.join("tmp/redis.sock")

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
  end

  class RedisManager < ServerManager
    def spawn
      begin
        ROOT.join("tmp/dump.rdb").rmtree
      rescue Errno::ENOENT
      end
      super
    end

    def command
      [
        Servers.redis_server_bin,
        "--unixsocket", REDIS_SOCKET_FILE.to_s,
        "--unixsocketperm", "700",
        "--port", real_port.to_s,
        "--tls-port", real_tls_port.to_s,
        "--tls-cert-file", CERTS_PATH.join("redis.crt").to_s,
        "--tls-key-file", CERTS_PATH.join("redis.key").to_s,
        "--tls-ca-cert-file", CERTS_PATH.join("ca.crt").to_s,
        "--save", "",
        "--appendonly", "no",
        "--dir", "tmp/",
      ]
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
      EOS
    end

    def conf_file
      ROOT.join("tmp/#{name}.conf")
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
      port: 26480,
      real_port: 26481,
      command: [],
    ),
    SentinelManager.new(
      "redis_sentinel_2",
      port: 26580,
      real_port: 26481,
      command: [],
    ),
    SentinelManager.new(
      "redis_sentinel_3",
      port: 26680,
      real_port: 26681,
      command: [],
    ),
  ].freeze

  class ToxiproxyManager < ServerManager
    BIN = CACHE_DIR.join("toxiproxy-server")

    def spawn
      system(ROOT.join("bin/install-toxiproxy").to_s) unless BIN.exist?
      super
    end

    def on_ready
      Toxiproxy.host = "http://#{host}:#{port}"

      Toxiproxy.populate(proxies)
    end

    def proxies
      proxies = [
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

      proxies += SENTINELS.map do |sentinel|
        {
          name: sentinel.name,
          upstream: "localhost:#{sentinel.real_port}",
          listen: ":#{sentinel.port}",
        }
      end

      proxies
    end
  end

  TOXIPROXY = ToxiproxyManager.new(
    "toxiproxy",
    port: 8474,
    command: [ToxiproxyManager::BIN.to_s, "-port", 8474.to_s],
  )

  TESTS = ServerList.new(
    TOXIPROXY,
    REDIS,
  )

  SENTINEL_TESTS = ServerList.new(
    TOXIPROXY,
    REDIS,
    REDIS_REPLICA,
    REDIS_REPLICA_2,
    *SENTINELS,
  )

  BENCHMARK = ServerList.new(REDIS)
end
