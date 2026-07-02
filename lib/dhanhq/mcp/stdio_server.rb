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
        @logger.level = ENV.fetch("DHAN_LOG_LEVEL", "WARN").upcase.then { |level| Logger.const_get(level) }
      end

      # Main server loop - blocks forever reading from STDIN
      def run
        $stdout.sync = true

        while (line = $stdin.gets)
          begin
            handle_request(line)
          rescue JSON::ParserError => e
            send_error(nil, -32_700, "Parse error", e.message)
          rescue StandardError => e
            @logger.error("Unhandled error: #{e.class}: #{e.message}")
            @logger.error(e.backtrace.join("\n"))
            send_error(nil, -32_603, "Internal error", e.message)
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
        when "prompts/list"
          handle_prompts_list(id)
        when "prompts/get"
          handle_prompts_get(id, params)
        when "resources/list"
          handle_resources_list(id)
        when "resources/read"
          handle_resources_read(id, params)
        else
          send_error(id, -32_601, "Method not found", "Unknown method: #{method}") if id
        end
      end

      def handle_initialize(id, _params)
        @initialized = true
        send_response(id, {
                        protocolVersion: PROTOCOL_VERSION,
                        capabilities: {
                          tools: { listChanged: false },
                          prompts: { listChanged: false },
                          resources: { listChanged: false },
                        },
                        serverInfo: {
                          name: "dhanhq-mcp",
                          version: Dhanhq::Mcp::VERSION,
                        },
                      })
      end

      def handle_initialized
        # Notification - no response required
        # Cursor sends this after initialize
      end

      def handle_tools_list(id)
        tools = Dhanhq::Mcp::ToolRegistry.tools.map { |tool| convert_tool_to_mcp_format(tool) }
        @logger.info("tools/list: returning #{tools.length} tools")
        @logger.info("TOOL_SPEC length: #{Dhanhq::Mcp::ToolRegistry.tools.length}")
        @logger.info("First tool name: #{tools.first["name"]}") if tools.any?
        send_response(id, { tools: tools })
      rescue StandardError => e
        @logger.error("Error in handle_tools_list: #{e.class}: #{e.message}")
        @logger.error(e.backtrace.join("\n"))
        send_error(id, -32_603, "Internal error", e.message)
      end

      def convert_tool_to_mcp_format(tool)
        schema = tool[:input_schema] || {}
        deep_stringify_keys({
                              name: tool[:name].to_s,
                              description: tool[:description].to_s,
                              annotations: {
                                scope: tool[:scope].to_s,
                                version: tool[:version].to_s,
                                risk: tool[:risk].to_s,
                              },
                              inputSchema: deep_stringify_keys(schema),
                            })
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
        send_error(id, -32_000, "Tool execution failed", e.message)
      end

      def send_response(id, result)
        response = deep_stringify_keys({
                                         jsonrpc: "2.0",
                                         id: id,
                                         result: result,
                                       })
        $stdout.puts(JSON.dump(response))
      end

      def handle_prompts_list(id)
        prompts = Dhanhq::Mcp::PROMPT_SPEC.map { |prompt| convert_prompt_to_mcp_format(prompt) }
        send_response(id, { prompts: prompts })
      end

      def convert_prompt_to_mcp_format(prompt)
        deep_stringify_keys({
                              name: prompt[:name].to_s,
                              description: prompt[:description].to_s,
                              arguments: (prompt[:arguments] || []).map do |arg|
                                {
                                  name: arg[:name].to_s,
                                  description: arg[:description].to_s,
                                  required: arg[:required] || false,
                                }
                              end,
                            })
      end

      def handle_prompts_get(id, params)
        prompt_name = params["name"]
        prompt_args = params["arguments"] || {}

        prompt = Dhanhq::Mcp::PROMPT_SPEC.find { |p| p[:name].to_s == prompt_name }
        unless prompt
          send_error(id, -32_602, "Invalid params", "Prompt not found: #{prompt_name}")
          return
        end

        messages = build_prompt_messages(prompt, prompt_args)
        send_response(id, {
                        messages: messages,
                      })
      end

      def build_prompt_messages(prompt, args)
        prompt_name = prompt[:name].to_s
        case prompt_name
        when "analyze_portfolio"
          build_analyze_portfolio_prompt(args)
        when "analyze_instrument"
          build_analyze_instrument_prompt(args)
        when "analyze_options_chain"
          build_analyze_options_chain_prompt(args)
        when "prepare_equity_trade"
          build_prepare_equity_trade_prompt(args)
        when "prepare_options_trade"
          build_prepare_options_trade_prompt(args)
        when "select_options_strike"
          build_select_options_strike_prompt(args)
        else
          [{ role: "user", content: "Unknown prompt: #{prompt[:name]}" }]
        end
      end

      def build_analyze_portfolio_prompt(args)
        content = "Analyze the current portfolio. "
        content += "Include holdings. " if args["include_holdings"] != false
        content += "Include positions. " if args["include_positions"] != false
        content += "Include available funds. " if args["include_funds"] != false
        content += "\n\nUse the portfolio tools to gather this information and provide a comprehensive analysis."
        [{ role: "user", content: content }]
      end

      def build_analyze_instrument_prompt(args)
        content = "Get comprehensive market data and analysis for #{args["symbol"]} (#{args["exchange_segment"]}).\n\n"
        content += "Steps:\n"
        content += "1. Use instrument.find to get instrument details\n"
        content += "2. Use instrument.info to get trading permissions\n"
        content += "3. Use instrument.ltp to get last traded price\n"
        content += "4. Use instrument.quote to get full market quote\n" if args["include_quote"] != false
        content += "5. Use instrument.ohlc to get OHLC data\n" if args["include_ohlc"] != false
        content += "\nProvide a comprehensive analysis of the instrument's current market status."
        [{ role: "user", content: content }]
      end

      def build_analyze_options_chain_prompt(args)
        expiry = args["expiry"] || "nearest expiry"
        content = "Analyze the options chain for #{args["symbol"]} "
        content += "(#{args["exchange_segment"]}) for expiry #{expiry}.\n\n"
        content += "Steps:\n"
        content += "1. Use option.expiries to get available expiries (if expiry not provided, use nearest)\n"
        content += "2. Use option.chain to get the full option chain for the expiry\n"
        content += "3. Analyze the chain data including strikes, premiums, open interest, and volume\n"
        content += "\nProvide insights on the options chain including:\n"
        content += "- ATM (At The Money) strikes\n"
        content += "- Premium ranges\n"
        content += "- Open interest distribution\n"
        [{ role: "user", content: content }]
      end

      def build_prepare_equity_trade_prompt(args)
        content = "Prepare a #{args["transaction_type"]} trade for #{args["symbol"]} (#{args["exchange_segment"]}).\n\n"
        content += "Trade details:\n"
        content += "- Quantity: #{args["quantity"]}\n"
        content += "- Order type: #{args["order_type"]}\n"
        content += "- Product type: #{args["product_type"]}\n"
        content += "- Price: #{args["price"]}\n" if args["price"]
        content += "- Stop loss: #{args["stop_loss"]}\n" if args["stop_loss"]
        content += "- Target: #{args["target"]}\n" if args["target"]
        content += "\nUse orders.prepare to prepare the trade intent with all risk checks."
        [{ role: "user", content: content }]
      end

      def build_prepare_options_trade_prompt(args)
        content = "Prepare an options #{args["option_type"]} trade for #{args["symbol"]}.\n\n"
        content += "Trade details:\n"
        content += "- Strike: #{args["strike"]}\n"
        content += "- Expiry: #{args["expiry"]}\n"
        content += "- Quantity: #{args["quantity"]} lots\n"
        content += "- Stop loss: #{args["stop_loss"]}\n" if args["stop_loss"]
        content += "- Target: #{args["target"]}\n" if args["target"]
        content += "\nFirst, use option.chain to get the security_id for this option,"
        content += " then use option.prepare to prepare the trade intent."
        [{ role: "user", content: content }]
      end

      def build_select_options_strike_prompt(args)
        content = "Select optimal option strike for #{args["symbol"]} "
        content += "(#{args["exchange_segment"]}) with #{args["direction"]} direction.\n\n"
        content += "Parameters:\n"
        content += "- Expiry: #{args["expiry"]}\n"
        content += "- Spot price: #{args["spot_price"]}\n"
        content += "- Direction: #{args["direction"]}\n"
        content += "- Max distance: #{args["max_distance_pct"] || 1.0}%\n"
        content += "- Premium range: ₹#{args["min_premium"] || 50} - ₹#{args["max_premium"] || 300}\n"
        content += "\nUse option.select to find the best matching strikes based on these criteria."
        [{ role: "user", content: content }]
      end

      def handle_resources_list(id)
        resources = Dhanhq::Mcp::RESOURCE_SPEC.map { |resource| convert_resource_to_mcp_format(resource) }
        send_response(id, { resources: resources })
      end

      def convert_resource_to_mcp_format(resource)
        deep_stringify_keys({
                              uri: resource[:uri].to_s,
                              name: resource[:name].to_s,
                              description: resource[:description].to_s,
                              mimeType: resource[:mime_type].to_s,
                            })
      end

      def handle_resources_read(id, params)
        uri = params["uri"]
        content = Resources.content_for(uri)

        unless content
          send_error(id, -32_602, "Invalid params", "Resource not found: #{uri}")
          return
        end

        resource = Dhanhq::Mcp::RESOURCE_SPEC.find { |r| r[:uri].to_s == uri }
        send_response(id, {
                        contents: [
                          {
                            uri: uri,
                            mimeType: resource[:mime_type],
                            text: content,
                          },
                        ],
                      })
      end

      def send_error(id, code, message, data = nil)
        error = {
          code: code,
          message: message,
        }
        error[:data] = data if data

        response = {
          jsonrpc: "2.0",
          id: id,
          error: error,
        }
        $stdout.puts(JSON.dump(response))
      end
    end
  end
end
