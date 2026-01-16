# frozen_string_literal: true

module Dhanhq
  module Mcp
    # MCP tool specifications
    TOOL_SPEC = [
      {
        name: "instrument.find",
        description: "Find tradable instrument",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
          },
          required: %w[exchange_segment symbol],
        },
      },
      {
        name: "instrument.info",
        description: "Trading permissions and risk metadata",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
          },
          required: %w[exchange_segment symbol],
        },
      },
    ].freeze
  end
end
