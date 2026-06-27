# frozen_string_literal: true

module Dhanhq
  module Mcp
    # MCP prompt specifications for trading workflows
    PROMPT_SPEC = [
      {
        name: "analyze_portfolio",
        description: "Analyze current portfolio holdings, positions, and funds",
        arguments: [
          {
            name: "include_holdings",
            description: "Include holdings analysis",
            required: false,
          },
          {
            name: "include_positions",
            description: "Include positions analysis",
            required: false,
          },
          {
            name: "include_funds",
            description: "Include available funds",
            required: false,
          },
        ],
      },
      {
        name: "analyze_instrument",
        description: "Get comprehensive market data and analysis for an instrument",
        arguments: [
          {
            name: "exchange_segment",
            description: "Exchange segment (e.g., NSE_EQ, IDX_I, NSE_FNO)",
            required: true,
          },
          {
            name: "symbol",
            description: "Trading symbol",
            required: true,
          },
          {
            name: "include_quote",
            description: "Include full market quote",
            required: false,
          },
          {
            name: "include_ohlc",
            description: "Include OHLC data",
            required: false,
          },
        ],
      },
      {
        name: "analyze_options_chain",
        description: "Analyze option chain for an index with expiries and chain data",
        arguments: [
          {
            name: "exchange_segment",
            description: "Exchange segment (typically IDX_I for indices)",
            required: true,
          },
          {
            name: "symbol",
            description: "Index symbol (e.g., NIFTY, BANKNIFTY)",
            required: true,
          },
          {
            name: "expiry",
            description: "Option expiry date (YYYY-MM-DD). If not provided, uses nearest expiry",
            required: false,
          },
        ],
      },
      {
        name: "prepare_equity_trade",
        description: "Prepare an equity or futures trade with risk checks",
        arguments: [
          {
            name: "exchange_segment",
            description: "Exchange segment (e.g., NSE_EQ, NSE_FNO)",
            required: true,
          },
          {
            name: "symbol",
            description: "Trading symbol",
            required: true,
          },
          {
            name: "transaction_type",
            description: "BUY or SELL",
            required: true,
          },
          {
            name: "quantity",
            description: "Number of shares/lots",
            required: true,
          },
          {
            name: "order_type",
            description: "MARKET or LIMIT",
            required: true,
          },
          {
            name: "product_type",
            description: "INTRADAY, CNC, or MARGIN",
            required: true,
          },
          {
            name: "price",
            description: "Limit price (required for LIMIT orders)",
            required: false,
          },
          {
            name: "stop_loss",
            description: "Stop loss price",
            required: false,
          },
          {
            name: "target",
            description: "Target price",
            required: false,
          },
        ],
      },
      {
        name: "prepare_options_trade",
        description: "Prepare an options buy trade with risk checks",
        arguments: [
          {
            name: "exchange_segment",
            description: "Exchange segment (typically IDX_I for index options)",
            required: true,
          },
          {
            name: "symbol",
            description: "Index symbol (e.g., NIFTY, BANKNIFTY)",
            required: true,
          },
          {
            name: "option_type",
            description: "CE (Call) or PE (Put)",
            required: true,
          },
          {
            name: "strike",
            description: "Strike price",
            required: true,
          },
          {
            name: "expiry",
            description: "Expiry date (YYYY-MM-DD)",
            required: true,
          },
          {
            name: "quantity",
            description: "Number of lots",
            required: true,
          },
          {
            name: "stop_loss",
            description: "Stop loss price",
            required: false,
          },
          {
            name: "target",
            description: "Target price",
            required: false,
          },
        ],
      },
      {
        name: "select_options_strike",
        description: "Select optimal option strike based on direction and filters",
        arguments: [
          {
            name: "exchange_segment",
            description: "Exchange segment (typically IDX_I for indices)",
            required: true,
          },
          {
            name: "symbol",
            description: "Index symbol (e.g., NIFTY, BANKNIFTY)",
            required: true,
          },
          {
            name: "expiry",
            description: "Expiry date (YYYY-MM-DD)",
            required: true,
          },
          {
            name: "direction",
            description: "BULLISH or BEARISH",
            required: true,
          },
          {
            name: "spot_price",
            description: "Current spot price",
            required: true,
          },
          {
            name: "max_distance_pct",
            description: "Maximum distance from spot as percentage (default: 1.0)",
            required: false,
          },
          {
            name: "min_premium",
            description: "Minimum premium filter (default: 50)",
            required: false,
          },
          {
            name: "max_premium",
            description: "Maximum premium filter (default: 300)",
            required: false,
          },
        ],
      },
    ].freeze
  end
end
