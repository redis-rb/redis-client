# frozen_string_literal: true

require "pathname"

module RedisServerHelper
  module_function

  ROOT = Pathname.new(File.expand_path("../../", __dir__))
  CERTS_PATH = ROOT.join("test/docker/files/certs")
  PID_FILE = ROOT.join("tmp/redis.pid")
  SOCKET_FILE = if ENV["CI"]
    Pathname.new("/var/redis/redis.sock")
  else
    ROOT.join("tmp/redis.sock")
  end

  HOST = "127.0.0.1"
  TCP_PORT = 1_6379
  TLS_PORT = 2_6379
  REAL_TCP_PORT = 1_6380
  REAL_TLS_PORT = 2_6380

  PASSWORD = "hunter2"

  def tcp_config
    {
      host: HOST,
      port: TCP_PORT,
      timeout: 0.1,
      driver: ENV.fetch("DRIVER", "ruby").to_sym,
      reconnect_attempts: false,
    }
  end

  def ssl_config
    {
      host: HOST,
      port: TLS_PORT,
      timeout: 0.1,
      reconnect_attempts: false,
      ssl: true,
      ssl_params: {
        verify_hostname: false, # TODO: See if we could actually verify the hostname with our CI and dev setup
        cert: CERTS_PATH.join("client.crt").to_s,
        key: CERTS_PATH.join("client.key").to_s,
        ca_file: CERTS_PATH.join("ca.crt").to_s,
      },
      driver: ENV.fetch("DRIVER", "ruby").to_sym,
    }
  end

  def unix_config
    {
      path: SOCKET_FILE.to_s,
      timeout: 0.1,
      reconnect_attempts: false,
      driver: ENV.fetch("DRIVER", "ruby").to_sym,
    }
  end

  def spawn
    if alive?
      $stderr.puts "redis-server already running with pid=#{pid}"
    else
      PID_FILE.parent.mkpath
      $stderr.print "starting redis-server... "
      pid = Process.spawn(
        "redis-server",
        "--unixsocket", SOCKET_FILE.to_s,
        "--unixsocketperm", "700",
        "--port", REAL_TCP_PORT.to_s,
        "--tls-port", REAL_TLS_PORT.to_s,
        "--tls-cert-file", CERTS_PATH.join("redis.crt").to_s,
        "--tls-key-file", CERTS_PATH.join("redis.key").to_s,
        "--tls-ca-cert-file", CERTS_PATH.join("ca.crt").to_s,
        "--save", "",
        "--appendonly", "no",
        out: ROOT.join("tmp/redis.log").to_s,
        err: ROOT.join("tmp/redis.log").to_s,
      )
      PID_FILE.write(pid.to_s)
      $stderr.print "started with pid=#{pid}... "
      wait_until_ready
      $stderr.puts "ready."
    end
  end

  def wait_until_ready(timeout: 5)
    (timeout * 100).times do
      TCPSocket.new(HOST, TCP_PORT)
      return true
    rescue Errno::ECONNREFUSED
      sleep 0.01
    end
    false
  end

  def shutdown
    if alive?
      pid = self.pid
      Process.kill("INT", pid)
      Process.wait(pid)
    end
    true
  rescue Errno::ESRCH, Errno::ECHILD
    true
  end

  def pid
    Integer(PID_FILE.read)
  rescue Errno::ENOENT
    nil
  end

  def alive?
    pid = self.pid
    return false unless pid

    pid && Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end
