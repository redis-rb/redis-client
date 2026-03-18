# frozen_string_literal: true

require "test_helper"

require "redis_client/hash_ring"
require "digest/sha1"

class RedisClient
  class HashRingTest < RedisClientTestCase
    include ClientTestHelper

    setup do
      @nodes = [
        new_client(db: 1, id: "cache-1"),
        new_client(db: 2, id: "cache-2"),
        new_client(db: 3, id: "cache-3"),
      ]
      @ring = HashRing.new(@nodes)
    end

    def test_node_for
      assert_equal @nodes[2], @ring.node_for("foo")
      assert_equal @nodes[0], @ring.node_for("bar")
      assert_equal @nodes[1], @ring.node_for("baz")

      assert_equal @nodes[0], @nodes[0].node_for("baz")
    end

    def test_custom_digest
      @ring = HashRing.new(@nodes, digest: Digest::SHA1)

      assert_equal @nodes[0], @ring.node_for("foo")
      assert_equal @nodes[2], @ring.node_for("bar")
      assert_equal @nodes[1], @ring.node_for("baz999")
    end

    def test_nodes_for
      mapping = @ring.nodes_for("foo", "bar", "baz", "egg", "spam", "plop")
      assert_equal 3, mapping.size

      assert_equal ["baz", "spam", "plop"], mapping[@nodes[1]]
      assert_equal ["bar", "egg"], mapping[@nodes[0]]
      assert_equal ["foo"], mapping[@nodes[2]]

      assert_equal mapping, @ring.nodes_for(["foo", "bar", "baz", "egg", "spam", "plop"])

      assert_equal({ @nodes[0] => ["foo", "bar"] }, @nodes[0].nodes_for("foo", "bar"))
    end

    def test_nodes
      assert_equal @nodes, @ring.nodes
      assert_equal [@nodes[0]], @nodes[0].nodes
    end

    private

    def new_client(**overrides)
      RedisClient.config(**tcp_config.merge(overrides)).new_pool
    end
  end
end
