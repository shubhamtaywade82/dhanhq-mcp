# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Rack-based HTTP server for MCP protocol
    class Server
      # Initialize server with context provider
      #
      # @param context_provider [Proc] callable that builds Context from Rack::Request
      def initialize(context_provider:)
        @context_provider = context_provider
      end

      # Handle Rack request
      #
      # @param env [Hash] Rack environment
      # @return [Array] Rack response tuple
      def call(env)
        req = Rack::Request.new(env)
        payload = JSON.parse(req.body.read)
        handle_mcp_request(req, payload)
      rescue StandardError => e
        error(e.message)
      end

      private

      def handle_mcp_request(req, payload)
        case payload["method"]
        when "tools/list"
          ok(TOOL_SPEC)
        when "tools/call"
          handle_tool_call(req, payload)
        else
          error("Unknown MCP method")
        end
      end

      def handle_tool_call(req, payload)
        ctx = @context_provider.call(req)
        result = Router.call(
          payload.dig("params", "name"),
          payload.dig("params", "arguments") || {},
          ctx,
        )
        ok(result)
      end

      def ok(result)
        [200, { "Content-Type" => "application/json" }, [JSON.dump(result: result)]]
      end

      def error(msg)
        [200, { "Content-Type" => "application/json" }, [JSON.dump(error: { message: msg })]]
      end
    end
  end
end
