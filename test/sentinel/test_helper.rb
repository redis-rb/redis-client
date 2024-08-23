# frozen_string_literal: true

require_relative "../env"
require_relative "../test_helper"

Servers.build_redis
Servers::SENTINEL_TESTS.prepare

require "minitest/autorun"
Minitest.after_run { Servers::TESTS.shutdown }
