# frozen_string_literal: true

require "json"
require "logger"

module Dhanhq
  module Mcp
    # STDIO-based MCP server for Cursor and other MCP hosts
    #
    # Implements JSON-RPC 2.0 protocol over STDIN/STDOUT with mandatory
    # MCP lifecycle: initialize -> initialized -> tools/list -> tools/call
    class StdioServer
      PROTOCOL_VERSION = "2024-11-05"

      def initialize(context:)
        @context = context
        @initialized = false
        @logger = Logger.new($stderr)
        @logger.level = Logger::WARN
      end

      # Main server loop - blocks forever reading from STDIN
      def run
        STDOUT.sync = true

        while (line = STDIN.gets)
          begin
            handle_request(line)
          rescue JSON::ParserError => e
            send_error(nil, -32700, "Parse error", e.message)
          rescue StandardError => e
            @logger.error("Unhandled error: #{e.class}: #{e.message}")
            @logger.error(e.backtrace.join("\n"))
            send_error(nil, -32603, "Internal error", e.message)
          end
        end
      end

      private

      def handle_request(line)
        request = JSON.parse(line.strip)
        return if request.nil?

        id = request["id"]
        method = request["method"]
        params = request["params"] || {}

        case method
        when "initialize"
          handle_initialize(id, params)
        when "initialized"
          handle_initialized
        when "tools/list"
          handle_tools_list(id)
        when "tools/call"
          handle_tools_call(id, params)
        else
          send_error(id, -32601, "Method not found", "Unknown method: #{method}") if id
        end
      end

      def handle_initialize(id, _params)
        @initialized = true
        send_response(id, {
          protocolVersion: PROTOCOL_VERSION,
          capabilities: { tools: {} },
          serverInfo: {
            name: "dhanhq-mcp",
            version: VERSION
          }
        })
      end

      def handle_initialized
        # Notification - no response required
        # Cursor sends this after initialize
      end

      def handle_tools_list(id)
        tools = TOOL_SPEC.map { |tool| convert_tool_to_mcp_format(tool) }
        send_response(id, { tools: tools })
      end

      def convert_tool_to_mcp_format(tool)
        schema = tool[:input_schema] || {}
        {
          name: tool[:name].to_s,
          description: tool[:description].to_s,
          inputSchema: deep_stringify_keys(schema)
        }
      end

      def deep_stringify_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(key, value), result|
            result[key.to_s] = deep_stringify_keys(value)
          end
        when Array
          obj.map { |item| deep_stringify_keys(item) }
        else
          obj
        end
      end

      def handle_tools_call(id, params)
        tool_name = params["name"]
        arguments = params["arguments"] || {}

        result = Router.call(tool_name, arguments, @context)
        send_response(id, result)
      rescue StandardError => e
        @logger.error("Tool call error: #{e.class}: #{e.message}")
        send_error(id, -32000, "Tool execution failed", e.message)
      end

      def send_response(id, result)
        response = {
          jsonrpc: "2.0",
          id: id,
          result: result
        }
        STDOUT.puts(JSON.dump(response))
      end

      def send_error(id, code, message, data = nil)
        error = {
          code: code,
          message: message
        }
        error[:data] = data if data

        response = {
          jsonrpc: "2.0",
          id: id,
          error: error
        }
        STDOUT.puts(JSON.dump(response))
      end
    end
  end
end
