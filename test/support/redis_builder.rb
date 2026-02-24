#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest/sha1'
require 'English'
require 'fileutils'
require 'net/http'

class RedisBuilder
  TARBALL_CACHE_EXPIRATION = 60 * 60 * 30

  def initialize(redis_branch, tmp_dir)
    @redis_branch = redis_branch
    @tmp_dir = tmp_dir
    @build_dir = Servers::CACHE_DIR.join("redis-#{redis_branch}").to_s
  end

  def bin_path
    File.join(@build_dir, "src/redis-server")
  end

  def install
    download_tarball_if_needed
    if old_checkum != checksum
      build
      update_checksum
    end
  end

  private

  def download_tarball_if_needed
    return if File.exist?(tarball_path) && File.mtime(tarball_path) > Time.now - TARBALL_CACHE_EXPIRATION

    FileUtils.mkdir_p(@tmp_dir)
    download(tarball_url, tarball_path)
  end

  def download(url, path)
    response = Net::HTTP.get_response(URI(url))
    case Integer(response.code)
    when 300..399
      download(response['Location'], path)
    when 200
      File.binwrite(tarball_path, response.body)
    else
      raise "Unexpected HTTP response #{response.code} #{url}"
    end
  end

  def tarball_path
    File.join(@tmp_dir, "redis-#{@redis_branch}.tar.gz")
  end

  def tarball_url
    "https://github.com/redis/redis/archive/#{@redis_branch}.tar.gz"
  end

  def build
    FileUtils.rm_rf(@build_dir)
    FileUtils.mkdir_p(@build_dir)
    command!('tar', 'xf', tarball_path, '-C', File.expand_path('../', @build_dir))
    Dir.chdir(@build_dir) do
      command!('make', 'BUILD_TLS=yes')
    end
  end

  def update_checksum
    File.write(checksum_path, checksum)
  end

  def old_checkum
    File.read(checksum_path)
  rescue Errno::ENOENT
    nil
  end

  def checksum_path
    File.join(@build_dir, 'build.checksum')
  end

  def checksum
    @checksum ||= Digest::SHA1.file(tarball_path).hexdigest
  end

  def command!(*args)
    puts "$ #{args.join(' ')}"
    raise "Command failed with status #{$CHILD_STATUS.exitstatus}" unless system(*args)
  end
end
