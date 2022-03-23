# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"
require "rake/testtask"
require 'rubocop/rake_task'

RuboCop::RakeTask.new

gemspec = Gem::Specification.load("redis-client.gemspec")
Rake::ExtensionTask.new do |ext|
  ext.name = "hiredis_connection"
  ext.ext_dir = "ext/redis_client/hiredis"
  ext.lib_dir = "lib/redis_client"
  ext.gem_spec = gemspec
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :benchmark do
  task :record do
    system("rm -rf tmp/*.benchmark")
    %w(single pipelined).each do |suite|
      system(RbConfig.ruby, "benchmark/#{suite}.rb")

      output_path = "benchmark/#{suite}.md"
      File.open(output_path, "w+") do |output|
        output.puts("ruby: `#{RUBY_DESCRIPTION}`\n\n")
        output.puts("redis-server: `#{`redis-server -v`.strip}`\n\n")
        output.puts
        output.flush
        system(RbConfig.ruby, "--yjit", "benchmark/#{suite}.rb", out: output)
      end

      skipping = false
      output = File.readlines(output_path).reject do |line|
        if skipping
          if line == "Comparison:\n"
            skipping = false
            true
          else
            skipping
          end
        else
          skipping = true if line.start_with?("Warming up ---")
          skipping
        end
      end
      File.write(output_path, output.join)
    end
  end
end

task default: %i[test rubocop]
