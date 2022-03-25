# frozen_string_literal: true

module ClientTestHelper
  def setup
    @redis = new_client
    @redis.call("FLUSHDB")
  end

  private

  def new_client(**overrides)
    RedisClient.new(**RedisServerHelper.tcp_config.merge(overrides))
  end
end
