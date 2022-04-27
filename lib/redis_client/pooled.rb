# frozen_string_literal: true

require "connection_pool"

class RedisClient
  class Pooled
    EMPTY_HASH = {}.freeze

    include Common

    def initialize(
      config,
      id: config.id,
      connect_timeout: config.connect_timeout,
      read_timeout: config.read_timeout,
      write_timeout: config.write_timeout,
      **kwargs
    )
      super(config, id: id, connect_timeout: connect_timeout, read_timeout: read_timeout, write_timeout: write_timeout)
      @pool_kwargs = kwargs
      @pool = new_pool
      @mutex = Mutex.new
    end

    def with(options = EMPTY_HASH)
      pool.with(options) do |client|
        client.connect_timeout = connect_timeout
        client.read_timeout = read_timeout
        client.write_timeout = write_timeout
        yield client
      end
    rescue ConnectionPool::TimeoutError => error
      raise CheckoutTimeoutError, "Couldn't checkout a connection in time: #{error.message}"
    end
    alias_method :then, :with

    def close
      if @pool
        @mutex.synchronize do
          pool = @pool
          @pool = nil
          pool&.shutdown(&:close)
        end
      end
      nil
    end

    def size
      pool.size
    end

    %w(pipelined).each do |method|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{method}(&block)
          with { |r| r.#{method}(&block) }
        end
      RUBY
    end

    %w(multi).each do |method|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{method}(**kwargs, &block)
          with { |r| r.#{method}(**kwargs, &block) }
        end
      RUBY
    end

    %w(call call_once blocking_call pubsub).each do |method|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{method}(*args)
          with { |r| r.#{method}(*args) }
        end
      RUBY
    end

    %w(scan sscan hscan zscan).each do |method|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          unless block_given?
            return to_enum(__callee__, *args)
          end

          with { |r| r.#{method}(*args, &block) }
        end
      RUBY
    end

    private

    def pool
      @pool ||= @mutex.synchronize { new_pool }
    end

    def new_pool
      ConnectionPool.new(**@pool_kwargs) { @config.new_client }
    end
  end
end
