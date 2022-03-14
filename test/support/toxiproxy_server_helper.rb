# frozen_string_literal: true

require "pathname"

module ToxiproxyServerHelper
  module_function

  ROOT = Pathname.new(File.expand_path("../../", __dir__))
  PID_FILE = ROOT.join("tmp/toxiproxy.pid")

  HOST = "localhost"
  PORT = 8474

  def url
    "http://#{HOST}:#{PORT}"
  end

  def spawn
    if alive?
      puts "toxiproxy-server already running with pid=#{pid}"
    else
      pid = Process.spawn(
        "toxiproxy-server",
        "-port", PORT.to_s,
        out: ROOT.join("tmp/toxiproxy.log").to_s,
        err: ROOT.join("tmp/toxiproxy.log").to_s,
      )
      PID_FILE.parent.mkpath
      PID_FILE.write(pid.to_s)
      puts "toxiproxy-server started with pid=#{pid}"
      wait_until_ready
    end
  end

  def wait_until_ready(timeout: 5)
    (timeout * 100).times do
      TCPSocket.new(HOST, PORT)
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
