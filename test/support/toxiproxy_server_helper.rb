# frozen_string_literal: true

require "pathname"

module ToxiproxyServerHelper
  module_function

  ROOT = Pathname.new(File.expand_path("../../", __dir__))
  PID_FILE = ROOT.join("tmp/toxiproxy.pid")
  BIN = ROOT.join("bin/toxiproxy-server")

  HOST = "localhost"
  PORT = 8474

  def url
    "http://#{HOST}:#{PORT}"
  end

  def spawn
    if alive?
      puts "toxiproxy-server already running with pid=#{pid}"
    else
      PID_FILE.parent.mkpath
      system(ROOT.join("bin/install-toxiproxy").to_s) unless BIN.exist?
      print "starting toxiproxy-server... "
      pid = Process.spawn(
        BIN.to_s,
        "-port", PORT.to_s,
        out: ROOT.join("tmp/toxiproxy.log").to_s,
        err: ROOT.join("tmp/toxiproxy.log").to_s,
      )
      PID_FILE.write(pid.to_s)
      print "started with pid=#{pid}... "
      wait_until_ready
      puts "ready."
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
