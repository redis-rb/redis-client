# frozen_string_literal: true

require "pathname"

module RedisServerHelper
  module_function

  ROOT = Pathname.new(File.expand_path("../../", __dir__))
  CERTS_PATH = ROOT.join("test/docker/files/certs")
  PID_FILE = ROOT.join("tmp/redis.pid")

  HOST = "localhost"
  TCP_PORT = 1_6379
  TLS_PORT = 2_6379
  REAL_TCP_PORT = 1_6380
  REAL_TLS_PORT = 2_6380

  def tcp_config
    {
      host: HOST,
      port: TCP_PORT,
      timeout: 1,
    }
  end

  def ssl_config
    {
      host: HOST,
      port: TLS_PORT,
      timeout: 1,
    }
  end

  def spawn
    if alive?
      puts "redis-server already running with pid=#{pid}"
    else
      print "starting redis-server... "
      pid = Process.spawn(
        "redis-server",
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
      PID_FILE.parent.mkpath
      PID_FILE.write(pid.to_s)
      print "started with pid=#{pid}... "
      wait_until_ready
      puts "ready."
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
