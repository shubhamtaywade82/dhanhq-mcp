# frozen_string_literal: true

module Dhanhq
  module Mcp
    # MCP execution context
    #
    # Carries dependencies and metadata for tool execution.
    # No auth, no ENV - caller supplies everything.
    class Context
      attr_reader :client, :meta, :policy

      # Initialize context with dependencies
      #
      # @param client [Object] DhanHQ client instance
      # @param meta [Hash] optional metadata
      # @param policy [Policy] permission policy for tool execution
      def initialize(client:, meta: {}, policy: Policy.default)
        @client = client
        @meta = meta
        @policy = policy
      end
    end
  end
end
