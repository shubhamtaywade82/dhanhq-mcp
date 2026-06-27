# frozen_string_literal: true

module Dhanhq
  module Mcp
    # MCP resource specifications for reference data
    RESOURCE_SPEC = [
      {
        uri: "dhanhq://reference/exchange-segments",
        name: "Exchange Segments",
        description: "Reference guide for exchange segment codes used in DhanHQ API",
        mime_type: "text/markdown",
      },
      {
        uri: "dhanhq://reference/product-types",
        name: "Product Types",
        description: "Reference guide for product types (INTRADAY, CNC, MARGIN)",
        mime_type: "text/markdown",
      },
      {
        uri: "dhanhq://reference/order-types",
        name: "Order Types",
        description: "Reference guide for order types (MARKET, LIMIT)",
        mime_type: "text/markdown",
      },
      {
        uri: "dhanhq://reference/trading-hours",
        name: "Trading Hours",
        description: "Reference guide for Indian stock market trading hours",
        mime_type: "text/markdown",
      },
      {
        uri: "dhanhq://reference/option-types",
        name: "Option Types",
        description: "Reference guide for option types (CE, PE)",
        mime_type: "text/markdown",
      },
    ].freeze

    # Resource content generators
    module Resources
      def self.exchange_segments
        <<~MARKDOWN
          # Exchange Segments Reference

          Exchange segments identify the trading venue and instrument category in DhanHQ API.

          ## Equity Segments

          | Code | Exchange | Description |
          |------|----------|-------------|
          | `NSE_EQ` | NSE | Equity stocks |
          | `BSE_EQ` | BSE | Equity stocks |

          ## Index Segments

          | Code | Exchange | Description |
          |------|----------|-------------|
          | `IDX_I` | NSE | Index (for options) |
          | `BSE_IDX` | BSE | Index |

          ## Futures & Options Segments

          | Code | Exchange | Description |
          |------|----------|-------------|
          | `NSE_FNO` | NSE | Futures & Options |
          | `BSE_FNO` | BSE | Futures & Options |

          ## Usage

          - Use `NSE_EQ` or `BSE_EQ` for equity stocks
          - Use `IDX_I` for index options (NIFTY, BANKNIFTY, etc.)
          - Use `NSE_FNO` for futures contracts
          - Always use the segment that matches your instrument type

          ## Examples

          ```ruby
          # Equity stock
          exchange_segment: "NSE_EQ"
          symbol: "RELIANCE"

          # Index for options
          exchange_segment: "IDX_I"
          symbol: "NIFTY"

          # Futures contract
          exchange_segment: "NSE_FNO"
          symbol: "NIFTY 26 FEB 2026 FUT"
          ```
        MARKDOWN
      end

      def self.product_types
        <<~MARKDOWN
          # Product Types Reference

          Product types determine how positions are held and margin requirements.

          ## Product Types

          | Type | Description | Holding Period | Margin Required |
          |------|------------|----------------|-----------------|
          | `INTRADAY` | Intraday trading | Same day only | Lower margin |
          | `CNC` | Cash and Carry | Delivery (T+2) | Full payment |
          | `MARGIN` | Margin trading | Overnight | Margin required |

          ## When to Use

          - **INTRADAY**: For day trading, positions must be squared off before market close
          - **CNC**: For delivery-based trading, shares are delivered after T+2 days
          - **MARGIN**: For overnight positions with margin facility

          ## Important Notes

          - INTRADAY positions are automatically squared off at market close
          - CNC requires full payment upfront
          - MARGIN allows leverage but requires margin maintenance
          - Product type affects risk checks and compliance validation
        MARKDOWN
      end

      def self.order_types
        <<~MARKDOWN
          # Order Types Reference

          Order types determine how orders are executed in the market.

          ## Order Types

          | Type | Description | Price Required | Execution |
          |------|------------|----------------|------------|
          | `MARKET` | Market order | No | Executed at current market price |
          | `LIMIT` | Limit order | Yes | Executed only at specified price or better |

          ## When to Use

          - **MARKET**: When you want immediate execution at current market price
          - **LIMIT**: When you want to control the execution price

          ## Important Notes

          - MARKET orders execute immediately but price may vary
          - LIMIT orders require `price` parameter
          - LIMIT orders may not execute if price is not reached
          - Use LIMIT for better price control, MARKET for speed
        MARKDOWN
      end

      def self.trading_hours
        <<~MARKDOWN
          # Trading Hours Reference

          Indian stock market trading hours and important timings.

          ## Regular Trading Hours

          | Session | Time (IST) | Description |
          |---------|------------|-------------|
          | Pre-Market | 09:00 - 09:15 | Pre-market session |
          | Regular Trading | 09:15 - 15:30 | Main trading session |
          | Post-Market | 15:40 - 16:00 | After-hours session |

          ## Market Holidays

          - Markets are closed on weekends (Saturday & Sunday)
          - Markets are closed on national holidays
          - Check NSE/BSE websites for holiday calendar

          ## Important Notes

          - Most trading happens during 09:15 - 15:30
          - INTRADAY positions must be squared off before 15:30
          - Market data is available during trading hours
          - Risk checks validate trading hours for order preparation
        MARKDOWN
      end

      def self.option_types
        <<~MARKDOWN
          # Option Types Reference

          Option types define whether an option is a Call or Put.

          ## Option Types

          | Type | Full Name | Description | Direction |
          |------|-----------|-------------|-----------|
          | `CE` | Call Option | Right to buy | Bullish |
          | `PE` | Put Option | Right to sell | Bearish |

          ## When to Use

          - **CE (Call)**: Use when you expect the underlying to go up
          - **PE (Put)**: Use when you expect the underlying to go down

          ## Important Notes

          - CE options profit when spot price > strike price
          - PE options profit when spot price < strike price
          - Both CE and PE are used for BUY trades only in this MCP server
          - Option selection uses `direction` parameter (BULLISH/BEARISH) to choose CE/PE
        MARKDOWN
      end

      def self.content_for(uri)
        case uri
        when "dhanhq://reference/exchange-segments"
          exchange_segments
        when "dhanhq://reference/product-types"
          product_types
        when "dhanhq://reference/order-types"
          order_types
        when "dhanhq://reference/trading-hours"
          trading_hours
        when "dhanhq://reference/option-types"
          option_types
        end
      end
    end
  end
end
