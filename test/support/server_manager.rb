# frozen_string_literal: true

require "pathname"

class ServerManager
  ROOT = Pathname.new(File.expand_path("../../", __dir__))

  attr_reader :name, :host, :port, :real_port, :command

  def initialize(name, port:, command: nil, real_port: port, host: "127.0.0.1")
    @name = name
    @host = host
    @port = port
    @real_port = real_port
    @command = command
  end

  def spawn
    if alive?
      $stderr.puts "#{name} already running with pid=#{pid}"
    else
      pid_file.parent.mkpath
      $stderr.print "starting #{name}... "
      pid = Process.spawn(*command, out: log_file.to_s, err: log_file.to_s)
      pid_file.write(pid.to_s)
      $stderr.puts "started with pid=#{pid}"
    end
  end

  def wait(timeout: 5)
    $stderr.print "Waiting for #{name} (port #{real_port})..."
    if wait_until_ready(timeout: timeout)
      $stderr.puts " ready."
    else
      $stderr.puts " timedout."
    end
  end

  def health_check
    TCPSocket.new(host, real_port)
    true
  rescue Errno::ECONNREFUSED
    false
  end

  def on_ready
    nil
  end

  def wait_until_ready(timeout: 5)
    (timeout * 100).times do
      if health_check
        on_ready
        return true
      else
        sleep 0.01
      end
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
    Integer(pid_file.read)
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

  private

  def pid_file
    @pid_file ||= ROOT.join("tmp/#{name}.pid")
  end

  def log_file
    @log_file ||= ROOT.join("tmp/#{name}.log")
  end
end

class ServerList
  def initialize(*servers)
    @servers = servers
  end

  def prepare
    shutdown
    @servers.each(&:spawn)
    @servers.each(&:wait)
  end
  alias_method :reset, :prepare

  def shutdown
    @servers.reverse_each(&:shutdown)
  end
end
