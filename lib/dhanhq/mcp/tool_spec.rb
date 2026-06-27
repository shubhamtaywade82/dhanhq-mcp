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
        description: "Find tradable instrument with complete details " \
                     "(security_id, symbol, display_name, underlying_symbol, segment, instrument)",
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
      {
        name: "option.filter_chain",
        description: "Advanced option chain filtering with multiple criteria (OI, volume, IV, Greeks, premium)",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            expiry: { type: "string" },
            spot_price: { type: "number" },
            filters: {
              type: "object",
              properties: {
                min_oi: { type: "integer" },
                min_volume: { type: "integer" },
                min_iv: { type: "number" },
                max_iv: { type: "number" },
                min_delta: { type: "number" },
                max_delta: { type: "number" },
                premium_range: { type: "array", items: { type: "number" } },
                option_type: { enum: %w[CE PE] },
                max_distance_pct: { type: "number" },
              },
            },
            sort_by: { type: "string", enum: %w[volume oi premium delta iv], default: "volume" },
            limit: { type: "integer", default: 10 },
          },
          required: %w[exchange_segment symbol expiry],
        },
      },
      {
        name: "option.risk_reward",
        description: "Calculate risk-reward metrics (max profit, max loss, breakeven, risk-reward ratio)",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            strike: { type: "number" },
            option_type: { enum: %w[CE PE] },
            premium: { type: "number" },
            quantity: { type: "integer" },
            spot_price: { type: "number" },
          },
          required: %w[exchange_segment symbol strike option_type premium quantity],
        },
      },
      {
        name: "option.probability",
        description: "Calculate probability metrics (probability of profit, ITM, breakeven)",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            strike: { type: "number" },
            option_type: { enum: %w[CE PE] },
            premium: { type: "number" },
            expiry: { type: "string" },
            spot_price: { type: "number" },
            iv: { type: "number" },
          },
          required: %w[exchange_segment symbol strike option_type premium expiry],
        },
      },
      {
        name: "option.theta_analysis",
        description: "Analyze theta decay over time - show how premium decays over remaining days",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            strike: { type: "number" },
            option_type: { enum: %w[CE PE] },
            premium: { type: "number" },
            expiry: { type: "string" },
            spot_price: { type: "number" },
            iv: { type: "number" },
            days_ahead: { type: "array", items: { type: "integer" } },
          },
          required: %w[exchange_segment symbol strike option_type premium expiry],
        },
      },
      {
        name: "option.iv_metrics",
        description: "Calculate IV percentile and rank to determine if options are expensive or cheap",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            expiry: { type: "string" },
            spot_price: { type: "number" },
          },
          required: %w[exchange_segment symbol expiry],
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
      # Streaming control
      {
        name: "stream.subscribe",
        description: "Subscribe to live market data for an instrument",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { type: "string" },
            symbol: { type: "string" },
            feed_type: { type: "string", enum: %w[LTP QUOTE FULL] },
          },
          required: %w[exchange_segment symbol feed_type],
        },
      },
      {
        name: "stream.unsubscribe",
        description: "Unsubscribe from live market data for an instrument",
        input_schema: {
          type: "object",
          properties: {
            subscription_id: { type: "string" },
          },
          required: %w[subscription_id],
        },
      },
      {
        name: "stream.status",
        description: "List active market data subscriptions",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      # Orders – execution
      {
        name: "orders.place",
        description: "Place a new order (execution)",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            correlation_id: { type: "string" },
            transaction_type: { enum: %w[BUY SELL] },
            exchange_segment: { enum: %w[NSE_EQ NSE_FNO NSE_COMM BSE_EQ BSE_FNO MCX_COMM] },
            product_type: { enum: %w[CNC INTRADAY MARGIN MTF CO BO] },
            order_type: { enum: %w[LIMIT MARKET STOP_LOSS STOP_LOSS_MARKET] },
            validity: { enum: %w[DAY IOC] },
            security_id: { type: "string" },
            quantity: { type: "integer" },
            disclosed_quantity: { type: "integer" },
            price: { type: "number" },
            trigger_price: { type: "number" },
            after_market_order: { type: "boolean" },
            amo_time: { enum: %w[PRE_OPEN OPEN OPEN_30 OPEN_60] },
            bo_profit_value: { type: "number" },
            bo_stop_loss_value: { type: "number" },
          },
          required: %w[transaction_type exchange_segment product_type order_type validity security_id quantity],
        },
      },
      {
        name: "orders.modify",
        description: "Modify a pending order",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
            order_type: { enum: %w[LIMIT MARKET STOP_LOSS STOP_LOSS_MARKET] },
            quantity: { type: "integer" },
            price: { type: "number" },
            disclosed_quantity: { type: "integer" },
            trigger_price: { type: "number" },
            validity: { enum: %w[DAY IOC] },
            leg_name: { enum: %w[ENTRY_LEG TARGET_LEG STOP_LOSS_LEG NA] },
          },
          required: %w[order_id],
        },
      },
      {
        name: "orders.cancel",
        description: "Cancel a pending order",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
          },
          required: %w[order_id],
        },
      },
      {
        name: "orders.get",
        description: "Get order details by order ID",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
          },
          required: %w[order_id],
        },
      },
      {
        name: "orders.get_by_correlation",
        description: "Get order details by correlation ID",
        input_schema: {
          type: "object",
          properties: {
            correlation_id: { type: "string" },
          },
          required: %w[correlation_id],
        },
      },
      {
        name: "orders.slice",
        description: "Slice order into multiple legs for quantities exceeding freeze limit",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
            dhan_client_id: { type: "string" },
            correlation_id: { type: "string" },
            transaction_type: { enum: %w[BUY SELL] },
            exchange_segment: { enum: %w[NSE_EQ NSE_FNO NSE_COMM BSE_EQ BSE_FNO MCX_COMM] },
            product_type: { enum: %w[CNC INTRADAY MARGIN MTF] },
            order_type: { enum: %w[LIMIT MARKET STOP_LOSS STOP_LOSS_MARKET] },
            validity: { enum: %w[DAY IOC] },
            security_id: { type: "string" },
            quantity: { type: "integer" },
            disclosed_quantity: { type: "integer" },
            price: { type: "number" },
            trigger_price: { type: "number" },
            after_market_order: { type: "boolean" },
            amo_time: { enum: %w[PRE_OPEN OPEN OPEN_30 OPEN_60] },
          },
          required: %w[order_id transaction_type exchange_segment product_type order_type validity quantity],
        },
      },
      {
        name: "orders.get_trades",
        description: "Get trades for a specific order",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
          },
          required: %w[order_id],
        },
      },
      {
        name: "orders.history",
        description: "Get trade history for a date range (paginated)",
        input_schema: {
          type: "object",
          properties: {
            from_date: { type: "string", format: "date" },
            to_date: { type: "string", format: "date" },
            page: { type: "integer", default: 0 },
          },
          required: %w[from_date to_date],
        },
      },
      # Super Orders
      {
        name: "super_orders.place",
        description: "Place a super order (bracket order with entry, target, stop-loss)",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            correlation_id: { type: "string" },
            transaction_type: { enum: %w[BUY SELL] },
            exchange_segment: { enum: %w[NSE_EQ NSE_FNO NSE_COMM BSE_EQ BSE_FNO MCX_COMM] },
            product_type: { enum: %w[CNC INTRADAY MARGIN MTF] },
            order_type: { enum: %w[LIMIT MARKET] },
            security_id: { type: "string" },
            quantity: { type: "integer" },
            price: { type: "number" },
            target_price: { type: "number" },
            stop_loss_price: { type: "number" },
            trailing_jump: { type: "number" },
          },
          required: %w[transaction_type exchange_segment product_type order_type security_id quantity price
                       target_price stop_loss_price trailing_jump],
        },
      },
      {
        name: "super_orders.modify",
        description: "Modify a super order leg",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
            dhan_client_id: { type: "string" },
            order_type: { enum: %w[LIMIT MARKET] },
            leg_name: { enum: %w[ENTRY_LEG TARGET_LEG STOP_LOSS_LEG] },
            quantity: { type: "integer" },
            price: { type: "number" },
            target_price: { type: "number" },
            stop_loss_price: { type: "number" },
            trailing_jump: { type: "number" },
          },
          required: %w[order_id leg_name],
        },
      },
      {
        name: "super_orders.cancel_leg",
        description: "Cancel a specific leg of a super order",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
            leg_name: { enum: %w[ENTRY_LEG TARGET_LEG STOP_LOSS_LEG] },
          },
          required: %w[order_id],
        },
      },
      {
        name: "super_orders.all",
        description: "Get all super orders for the day",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "super_orders.get",
        description: "Get super order by ID",
        input_schema: {
          type: "object",
          properties: {
            order_id: { type: "string" },
          },
          required: %w[order_id],
        },
      },
      # Conditional Triggers
      {
        name: "conditional_triggers.place",
        description: "Create a new conditional trigger",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            condition: {
              type: "object",
              properties: {
                comparison_type: { enum: %w[TECHNICAL_WITH_VALUE TECHNICAL_WITH_INDICATOR TECHNICAL_WITH_CLOSE
                                            PRICE_WITH_VALUE] },
                exchange_segment: { enum: %w[NSE_EQ BSE_EQ IDX_I] },
                security_id: { type: "string" },
                indicator_name: { type: "string" },
                time_frame: { enum: %w[DAY ONE_MIN FIVE_MIN FIFTEEN_MIN] },
                operator: { enum: %w[CROSSING_UP CROSSING_DOWN CROSSING_ANY_SIDE GREATER_THAN LESS_THAN
                                     GREATER_THAN_EQUAL LESS_THAN_EQUAL EQUAL NOT_EQUAL] },
                comparing_value: { type: "number" },
                comparing_indicator_name: { type: "string" },
                exp_date: { type: "string", format: "date" },
                frequency: { enum: %w[ONCE] },
                user_note: { type: "string" },
              },
              required: %w[comparison_type exchange_segment security_id time_frame operator exp_date frequency],
            },
            orders: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  transaction_type: { enum: %w[BUY SELL] },
                  exchange_segment: { enum: %w[NSE_EQ NSE_FNO NSE_COMM BSE_EQ BSE_FNO MCX_COMM] },
                  product_type: { enum: %w[CNC INTRADAY MARGIN MTF] },
                  order_type: { enum: %w[LIMIT MARKET STOP_LOSS STOP_LOSS_MARKET] },
                  security_id: { type: "string" },
                  quantity: { type: "integer" },
                  validity: { enum: %w[DAY IOC] },
                  price: { type: "string" },
                  disc_quantity: { type: "string" },
                  trigger_price: { type: "string" },
                },
                required: %w[transaction_type exchange_segment product_type order_type security_id quantity validity
                             price],
              },
            },
          },
          required: %w[condition orders],
        },
      },
      {
        name: "conditional_triggers.modify",
        description: "Modify an existing conditional trigger",
        input_schema: {
          type: "object",
          properties: {
            alert_id: { type: "string" },
            condition: { type: "object" },
            orders: { type: "array" },
          },
          required: %w[alert_id],
        },
      },
      {
        name: "conditional_triggers.delete",
        description: "Delete a conditional trigger",
        input_schema: {
          type: "object",
          properties: {
            alert_id: { type: "string" },
          },
          required: %w[alert_id],
        },
      },
      {
        name: "conditional_triggers.all",
        description: "Get all conditional triggers",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "conditional_triggers.get",
        description: "Get conditional trigger by ID",
        input_schema: {
          type: "object",
          properties: {
            alert_id: { type: "string" },
          },
          required: %w[alert_id],
        },
      },
      # Positions
      {
        name: "positions.convert",
        description: "Convert position between product types (e.g., INTRADAY to CNC)",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            from_product_type: { enum: %w[CNC INTRADAY MARGIN CO BO] },
            to_product_type: { enum: %w[CNC INTRADAY MARGIN CO BO] },
            exchange_segment: { enum: %w[NSE_EQ NSE_FNO NSE_COMM BSE_EQ BSE_FNO MCX_COMM] },
            position_type: { enum: %w[LONG SHORT CLOSED] },
            security_id: { type: "string" },
            trading_symbol: { type: "string" },
            convert_qty: { type: "integer" },
          },
          required: %w[dhan_client_id from_product_type to_product_type exchange_segment position_type security_id
                       convert_qty],
        },
      },
      {
        name: "positions.exit_all",
        description: "Exit all open positions at market price",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "positions.active",
        description: "Get only active (open) positions",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      # Margin Calculator
      {
        name: "margin.calculate",
        description: "Calculate margin for a single order",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            exchange_segment: { enum: %w[NSE_EQ NSE_FNO BSE_EQ BSE_FNO MCX_COMM] },
            transaction_type: { enum: %w[BUY SELL] },
            quantity: { type: "integer" },
            product_type: { enum: %w[CNC INTRADAY MARGIN MTF CO BO] },
            security_id: { type: "string" },
            price: { type: "number" },
            trigger_price: { type: "number" },
          },
          required: %w[dhan_client_id exchange_segment transaction_type quantity product_type security_id price],
        },
      },
      {
        name: "margin.calculate_multi",
        description: "Calculate combined margin for multiple orders with hedge benefits",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            include_position: { enum: %w[true false] },
            include_order: { enum: %w[true false] },
            scrip_list: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  exchange_segment: { enum: %w[NSE_EQ NSE_FNO NSE_COMM BSE_EQ BSE_FNO MCX_COMM] },
                  transaction_type: { enum: %w[BUY SELL] },
                  quantity: { type: "integer" },
                  product_type: { enum: %w[CNC INTRADAY MARGIN MTF] },
                  security_id: { type: "string" },
                  price: { type: "number" },
                  trigger_price: { type: "number" },
                },
                required: %w[exchange_segment transaction_type quantity product_type security_id],
              },
            },
          },
          required: %w[dhan_client_id scrip_list],
        },
      },
      # Trader's Control
      {
        name: "traders_control.kill_switch_status",
        description: "Get current kill switch status",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "traders_control.activate_kill_switch",
        description: "Activate kill switch (disables trading for the day)",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "traders_control.deactivate_kill_switch",
        description: "Deactivate kill switch (re-enables trading)",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "traders_control.configure_pnl_exit",
        description: "Configure P&L based automatic exit",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            profit_value: { type: "number" },
            loss_value: { type: "number" },
            product_type: { type: "array", items: { enum: %w[INTRADAY DELIVERY] } },
            enable_kill_switch: { type: "boolean" },
          },
          required: [],
        },
      },
      {
        name: "traders_control.get_pnl_exit",
        description: "Get current P&L exit configuration",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "traders_control.stop_pnl_exit",
        description: "Stop P&L based exit",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      # EDIS
      {
        name: "edis.tpin",
        description: "Generate T-PIN for EDIS authorization",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "edis.form",
        description: "Generate eDIS form for single stock",
        input_schema: {
          type: "object",
          properties: {
            isin: { type: "string" },
            qty: { type: "integer" },
            exchange: { enum: %w[NSE BSE] },
            segment: { enum: %w[EQ] },
            bulk: { type: "boolean" },
          },
          required: %w[isin qty exchange segment],
        },
      },
      {
        name: "edis.bulk_form",
        description: "Generate bulk eDIS form for multiple stocks",
        input_schema: {
          type: "object",
          properties: {
            exchange: { enum: %w[NSE BSE] },
            segment: { enum: %w[EQ] },
            bulk: { type: "boolean" },
          },
          required: %w[exchange segment],
        },
      },
      {
        name: "edis.inquire",
        description: "Check EDIS status for ISIN or ALL holdings",
        input_schema: {
          type: "object",
          properties: {
            isin: { type: "string" },
          },
          required: %w[isin],
        },
      },
      # Statements
      {
        name: "statements.ledger",
        description: "Get ledger report for date range",
        input_schema: {
          type: "object",
          properties: {
            from_date: { type: "string", format: "date" },
            to_date: { type: "string", format: "date" },
          },
          required: %w[from_date to_date],
        },
      },
      {
        name: "statements.trade_history",
        description: "Get trade history for date range (paginated)",
        input_schema: {
          type: "object",
          properties: {
            from_date: { type: "string", format: "date" },
            to_date: { type: "string", format: "date" },
            page: { type: "integer", default: 0 },
          },
          required: %w[from_date to_date],
        },
      },
      # Account
      {
        name: "account.get_ip",
        description: "Get configured static IP addresses",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "account.set_ip",
        description: "Set primary or secondary static IP",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            ip: { type: "string" },
            ip_flag: { enum: %w[PRIMARY SECONDARY] },
          },
          required: %w[dhan_client_id ip ip_flag],
        },
      },
      {
        name: "account.modify_ip",
        description: "Modify primary or secondary static IP",
        input_schema: {
          type: "object",
          properties: {
            dhan_client_id: { type: "string" },
            ip: { type: "string" },
            ip_flag: { enum: %w[PRIMARY SECONDARY] },
          },
          required: %w[dhan_client_id ip ip_flag],
        },
      },
      {
        name: "account.profile",
        description: "Get user profile information",
        input_schema: {
          type: "object",
          properties: {},
        },
      },
      # Expired Options Data
      {
        name: "expired_options_data.get",
        description: "Get historical rolling options data with OHLC, IV, OI",
        input_schema: {
          type: "object",
          properties: {
            exchange_segment: { enum: %w[NSE_FNO BSE_FNO] },
            interval: { enum: %w[1 5 15 30 60] },
            security_id: { type: "string" },
            instrument: { enum: %w[OPTIDX OPTSTK] },
            expiry_flag: { enum: %w[WEEK MONTH] },
            expiry_code: { enum: %w[1 2 3] },
            strike: { type: "string" },
            drv_option_type: { enum: %w[CALL PUT] },
            required_data: { type: "array", items: { enum: %w[open high low close iv volume strike oi spot] } },
            from_date: { type: "string", format: "date" },
            to_date: { type: "string", format: "date" },
          },
          required: %w[exchange_segment security_id instrument expiry_flag expiry_code strike drv_option_type
                       required_data from_date to_date],
        },
      },
    ].freeze
  end
end
