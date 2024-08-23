# frozen_string_literal: true

require "test_helper"

class RedisClient
  class CircuitBreakerTest < RedisClientTestCase
    include ClientTestHelper

    def setup
      super
      @circuit_breaker = CircuitBreaker.new(
        error_threshold: 3,
        error_threshold_timeout: 2,
        success_threshold: 2,
        error_timeout: 1,
      )
    end

    def test_open_circuit_after_consecutive_errors
      open_circuit @circuit_breaker
      assert_open @circuit_breaker
    end

    def test_allow_use_after_the_errors_timedout
      open_circuit @circuit_breaker
      assert_open @circuit_breaker

      travel(@circuit_breaker.error_threshold_timeout) do
        assert_closed(@circuit_breaker)
      end
    end

    def test_reopen_immediately_when_half_open
      open_circuit @circuit_breaker
      assert_open @circuit_breaker

      travel(@circuit_breaker.error_timeout) do
        record_error(@circuit_breaker)
        assert_open(@circuit_breaker)
      end
    end

    def test_close_fully_after_success_threshold_is_reached
      open_circuit @circuit_breaker
      assert_open @circuit_breaker

      travel(@circuit_breaker.error_timeout) do
        @circuit_breaker.success_threshold.times do
          assert_closed(@circuit_breaker)
        end

        record_error(@circuit_breaker)
        assert_closed(@circuit_breaker)
      end
    end

    private

    def assert_open(circuit_breaker)
      assert_raises CircuitBreaker::OpenCircuitError do
        circuit_breaker.protect do
          # noop
        end
      end
    end

    def assert_closed(circuit_breaker)
      assert_equal(:result, circuit_breaker.protect { :result })
    end

    def open_circuit(circuit_breaker)
      circuit_breaker.error_threshold.times do
        record_error(circuit_breaker)
      end
    end

    def record_error(circuit_breaker)
      assert_raises CannotConnectError do
        circuit_breaker.protect do
          raise CannotConnectError, "Oh no!"
        end
      end
    end
  end
end
