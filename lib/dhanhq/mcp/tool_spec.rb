# frozen_string_literal: true

module Dhanhq
  module Mcp
    # MCP tool specifications
    TOOL_SPEC = [
      # Portfolio tools (read-only)
      {
        name: "portfolio.holdings",
        description: "Get current holdings",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "portfolio.positions",
        description: "Get current positions",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "portfolio.funds",
        description: "Get available funds",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "portfolio.orders",
        description: "Get order book",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "portfolio.trades",
        description: "Get trade book",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      # Instrument tools
      {
        name: "instrument.find",
        description: "Find tradable instrument with complete details (security_id, symbol, display_name, underlying_symbol, segment, instrument)",
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
      # Market data – instrument driven
      {
        name: "instrument.ltp",
        description: "Get last traded price via Instrument",
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
        name: "instrument.quote",
        description: "Get full market quote via Instrument",
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
        name: "instrument.ohlc",
        description: "Get OHLC snapshot via Instrument",
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
        name: "instrument.daily",
        description: "Get daily historical candles via Instrument",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            from: { type: "string" },
            to: { type: "string" },
          },
          required: %w[exchange_segment symbol from to],
        },
      },
      {
        name: "instrument.intraday",
        description: "Get intraday candles via Instrument",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            from: { type: "string" },
            to: { type: "string" },
            interval: { type: "string" },
          },
          required: %w[exchange_segment symbol from to interval],
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
      # Orders – equity/futures trade intent
      {
        name: "orders.prepare",
        description: "Prepare equity/futures trade intent (no execution)",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            transaction_type: { enum: %w[BUY SELL] },
            quantity: { type: "integer" },
            order_type: { enum: %w[MARKET LIMIT] },
            product_type: { enum: %w[INTRADAY CNC MARGIN] },
            price: { type: "number" },
            stop_loss: { type: "number" },
            target: { type: "number" },
          },
          required: %w[exchange_segment symbol transaction_type quantity order_type product_type],
        },
      },
    ].freeze
  end
end
