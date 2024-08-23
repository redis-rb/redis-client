# frozen_string_literal: true

require_relative "../env"
require_relative "../test_helper"

Servers.build_redis
Servers::SENTINEL_TESTS.prepare
Servers.all = Servers::SENTINEL_TESTS
