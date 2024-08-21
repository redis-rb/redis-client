# frozen_string_literal: true

require "pathname"

class ServerManager
  ROOT = Pathname.new(File.expand_path("../../", __dir__))

  class << self
    def kill_all
      Dir[ROOT.join("tmp/**/*.pid").to_s].each do |pid_file|
        pid = begin
          Integer(File.read(pid_file))
        rescue ArgumentError
          nil
        end

        if pid
          begin
            Process.kill(:KILL, pid)
          rescue Errno::ESRCH, Errno::ECHILD
            nil # It's fine
          end
        end

        File.unlink(pid_file)
      end
    end
  end

  @worker_index = nil
  singleton_class.attr_accessor :worker_index

  module NullIO
    extend self

    def puts(_str)
      nil
    end

    def print(_str)
      nil
    end
  end

  attr_reader :name, :host, :command
  attr_accessor :out

  def initialize(name, port:, command: nil, real_port: port, host: "127.0.0.1")
    @name = name
    @host = host
    @port = port
    @real_port = real_port
    @command = command
    @out = $stderr
  end

  def worker_index
    ServerManager.worker_index
  end

  def port_offset
    worker_index.to_i * 200
  end

  def port
    @port + port_offset
  end

  def real_port
    @real_port + port_offset
  end

  def spawn
    shutdown

    pid_file.parent.mkpath
    pid = Process.spawn(*command.map(&:to_s), out: log_file.to_s, err: log_file.to_s)
    pid_file.write(pid.to_s)
    @out.puts "started #{name}-#{worker_index.to_i} with pid=#{pid}"
  end

  def wait(timeout: 5)
    unless wait_until_ready(timeout: 1)
      @out.puts "Waiting for #{name}-#{worker_index.to_i} (port #{real_port})..."
    end

    if wait_until_ready(timeout: timeout - 1)
      @out.puts "#{name}-#{worker_index.to_i} ready."
      true
    else
      @out.puts "#{name}-#{worker_index.to_i} timedout."
      false
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
  rescue Errno::ENOENT, ArgumentError
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

  def dir
    ROOT.join("tmp/#{name}-#{worker_index.to_i}").tap(&:mkpath)
  end

  def pid_file
    dir.join("#{name}.pid")
  end

  def log_file
    dir.join("#{name}.log")
  end
end

class ServerList
  def initialize(*servers)
    @servers = servers
  end

  def silence
    @servers.each { |s| s.out = ServerManager::NullIO }
    yield
  ensure
    @servers.each { |s| s.out = $stderr }
  end

  def prepare
    shutdown
    @servers.each(&:spawn)
    @servers.all?(&:wait)
  end

  def reset
    silence { prepare }
  end

  def shutdown
    @servers.reverse_each(&:shutdown)
  end
end
