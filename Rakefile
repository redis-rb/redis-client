# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require 'rubocop/rake_task'
RuboCop::RakeTask.new

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :benchmark do
  task :record do
    %w(single pipelined).each do |suite|
      File.open("benchmark/#{suite}.md", "w+") do |output|
        output.puts("ruby: `#{RUBY_DESCRIPTION}`\n")
        output.puts("redis-server: `#{`redis-server -v`.strip}`\n")
        output.puts
        output.flush
        system("ruby", "benchmark/#{suite}.rb", out: output)
      end
    end
  end
end

task default: %i[test rubocop]
