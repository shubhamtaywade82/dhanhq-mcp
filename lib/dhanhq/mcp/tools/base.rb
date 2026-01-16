# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Base class for all MCP tools
      class Base
        attr_reader :context

        # Initialize tool with execution context
        #
        # @param context [Context] execution context
        def initialize(context)
          @context = context
        end
      end
    end
  end
end
