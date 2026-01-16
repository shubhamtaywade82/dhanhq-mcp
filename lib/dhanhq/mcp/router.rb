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
          route_market(tool_name, args, context) ||
          route_option(tool_name, args, context) ||
          route_orders(tool_name, args, context) ||
          raise(Errors::UnknownTool, tool_name)
      end

      def self.route_instrument(tool_name, args, context)
        return unless tool_name.start_with?("instrument.")

        action = tool_name.split(".").last
        Tools::Instrument.new(context).public_send(action, args)
      end

      def self.route_market(tool_name, args, context)
        case tool_name
        when "instrument.ltp", "instrument.quote", "instrument.ohlc",
             "instrument.daily", "instrument.intraday"
          route_instrument(tool_name, args, context)
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

      def self.route_orders(tool_name, args, context)
        case tool_name
        when "orders.prepare"
          Tools::Orders.new(context).prepare(args)
        end
      end
    end
  end
end
