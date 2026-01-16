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
      def self.call(tool_name, args, context)
        route_instrument(tool_name, args, context) ||
          route_option(tool_name, args, context) ||
          raise(Errors::UnknownTool, tool_name)
      end

      def self.route_instrument(tool_name, args, context)
        case tool_name
        when "instrument.find"
          Tools::Instrument.new(context).find(args)
        when "instrument.info"
          Tools::Instrument.new(context).info(args)
        end
      end

      def self.route_option(tool_name, args, context)
        case tool_name
        when "option.expiries"
          Tools::Options::Expiries.new(context).call(args)
        when "option.chain"
          Tools::Options::Chain.new(context).call(args)
        when "option.select"
          Tools::Options::Selector.new(context).call(args)
        when "option.prepare"
          Tools::Options::Prepare.new(context).call(args)
        end
      end
    end
  end
end
