# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Error classes for MCP operations
    module Errors
      # Base error for all MCP operations
      class McpError < StandardError; end

      # Raised when tool name is not recognized
      class UnknownTool < McpError; end

      # Raised when tool arguments are invalid
      class InvalidArguments < McpError; end

      # Raised when operation violates risk rules
      class RiskViolation < McpError; end
    end
  end
end
