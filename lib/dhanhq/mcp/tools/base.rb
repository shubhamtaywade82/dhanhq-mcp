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

        private

        def with_risk_bridge
          yield
        rescue DhanHQ::RiskViolation => e
          raise Errors::RiskViolation, e.message
        end

        # Reference time for risk checks; injectable via context.meta[:now] in tests.
        def current_time
          context.meta[:now] || context.meta["now"] || Time.now
        end
      end
    end
  end
end
