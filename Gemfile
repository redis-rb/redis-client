# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in redis-client.gemspec
gemspec name: "redis-client"

gem "megatest"
gem "rake", "~> 13.3"
gem "rake-compiler"
gem "rubocop"
gem "base64"
gem "rubocop-minitest"
gem "toxiproxy"
gem "benchmark"

group :benchmark do
  gem "benchmark-ips"
  gem "hiredis"
  gem "redis", "~> 4.6"
  gem "stackprof", platform: :mri
end

gem "byebug", platform: :mri
