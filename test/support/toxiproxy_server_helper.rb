# frozen_string_literal: true

require "net/http"
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
      $stderr.puts "toxiproxy-server already running with pid=#{pid}"
    else
      PID_FILE.parent.mkpath
      system(ROOT.join("bin/install-toxiproxy").to_s) unless BIN.exist?
      $stderr.print "starting toxiproxy-server... "
      pid = Process.spawn(
        BIN.to_s,
        "-port", PORT.to_s,
        out: ROOT.join("tmp/toxiproxy.log").to_s,
        err: ROOT.join("tmp/toxiproxy.log").to_s,
      )
      PID_FILE.write(pid.to_s)
      $stderr.puts "started with pid=#{pid}... "
    end
  end

  def wait(timeout: 5)
    $stderr.print "Waiting for toxiproxy-server..."
    if wait_until_ready(timeout: timeout)
      $stderr.puts " ready."
    else
      $stderr.puts " timedout."
    end
  end

  def wait_until_ready(timeout: 5)
    (timeout * 100).times do
      Net::HTTP.get(URI("http://localhost:8474"))
      return true
    rescue SystemCallError
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
