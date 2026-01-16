# frozen_string_literal: true

module Dhanhq
  module Mcp
    # MCP execution context
    #
    # Carries dependencies and metadata for tool execution.
    # No auth, no ENV - caller supplies everything.
    class Context
      attr_reader :client, :meta

      # Initialize context with dependencies
      #
      # @param client [Object] DhanHQ client instance
      # @param meta [Hash] optional metadata
      def initialize(client:, meta: {})
        @client = client
        @meta = meta
      end
    end
  end
end
