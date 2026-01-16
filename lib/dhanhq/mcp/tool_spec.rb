# frozen_string_literal: true

module Dhanhq
  module Mcp
    # MCP tool specifications
    TOOL_SPEC = [
      # Instrument tools
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
      # Options – instrument driven
      {
        name: "option.expiries",
        description: "Get available option expiries for an index instrument",
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
        name: "option.chain",
        description: "Fetch option chain for an expiry via Instrument",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            expiry: { type: "string" },
          },
          required: %w[exchange_segment symbol expiry],
        },
      },
      {
        name: "option.select",
        description: "Rule-based CE/PE strike selection (no prediction)",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            expiry: { type: "string" },
            direction: { enum: %w[BULLISH BEARISH] },
            spot_price: { type: "number" },
            max_distance_pct: { type: "number", default: 1.0 },
            min_premium: { type: "number", default: 50 },
            max_premium: { type: "number", default: 300 },
          },
          required: %w[exchange_segment symbol expiry direction spot_price],
        },
      },
      {
        name: "option.prepare",
        description: "Prepare an OPTIONS BUY trade intent (no execution)",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            security_id: { type: "string" },
            option_type: { enum: %w[CE PE] },
            strike: { type: "number" },
            expiry: { type: "string" },
            quantity: { type: "integer" },
            stop_loss: { type: "number" },
            target: { type: "number" },
          },
          required: %w[exchange_segment symbol security_id option_type strike expiry quantity],
        },
      },
    ].freeze
  end
end
