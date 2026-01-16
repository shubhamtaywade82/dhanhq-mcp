# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Routes MCP tool calls to appropriate handlers
    class Router
      # Route tool call to handler
      #
      # @param tool_name [String] name of the tool to call
      # @param args [Hash] tool arguments
      # @param context [Context] execution context
      # @return [Hash] tool result
      # @raise [Errors::UnknownTool] when tool is not found
      def self.call(tool_name, _args, _context)
        raise Errors::UnknownTool, tool_name
      end
    end
  end
end
