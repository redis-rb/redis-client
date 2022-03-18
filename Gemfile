# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in redis-client.gemspec
gemspec

gem "minitest"
gem "rake", "~> 13.0"
gem "rubocop"
gem "rubocop-minitest"
gem "toxiproxy"

group :benchmark do
  gem "benchmark-ips"
  gem "redis", "~> 4.6"
  gem "hiredis"
end
