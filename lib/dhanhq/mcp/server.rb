# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Experimental Rack-based HTTP facade.
    #
    # STDIO is the canonical MCP transport; this class is retained only for
    # lightweight local integrations that expect a Rack app.
    class Server
      # Initialize server with context provider.
      def initialize(context_provider:)
        @context_provider = context_provider
      end

      # @param env [Hash] Rack environment
      # @return [Array] Rack response tuple
      def call(env)
        req = Rack::Request.new(env)
        payload = JSON.parse(req.body.read)
        handle_mcp_request(req, payload)
      rescue JSON::ParserError
        error(nil, "Invalid JSON payload")
      rescue StandardError => e
        error(nil, "Server error: #{e.message}")
      end

      private

      def handle_mcp_request(req, payload)
        case payload["method"]
        when "tools/list"
          ok(payload["id"], ToolRegistry.tools)
        when "tools/call"
          handle_tool_call(req, payload)
        else
          error(payload["id"], "Unknown MCP method")
        end
      end

      def handle_tool_call(req, payload)
        ctx = @context_provider.call(req)
        result = Router.call(
          payload.dig("params", "name"),
          payload.dig("params", "arguments") || {},
          ctx,
        )
        ok(payload["id"], result)
      rescue StandardError => e
        error(payload["id"], "Tool execution failed: #{e.message}")
      end

      def ok(id, result)
        [200, { "Content-Type" => "application/json" }, [JSON.dump(jsonrpc: "2.0", id: id, result: result)]]
      end

      def error(id, msg)
        [200, { "Content-Type" => "application/json" },
         [JSON.dump(jsonrpc: "2.0", id: id, error: { code: -32_603, message: msg })]]
      end
    end
  end
end
