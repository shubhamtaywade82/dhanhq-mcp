# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Routes MCP tool calls through the tool registry.
    class Router
      # Route tool call to a registered handler.
      #
      # @param tool_name [String] name of the tool to call
      # @param args [Hash] tool arguments
      # @param context [Context] execution context
      # @return [Hash,Array,Object] tool result
      # @raise [Errors::UnknownTool] when tool is not found
      # @raise [Errors::PermissionDenied] when policy blocks execution
      def self.call(tool_name, args, context)
        Validator.validate!(tool_name, args)
        ToolRegistry.call(tool_name, args, context)
      end
    end
  end
end
