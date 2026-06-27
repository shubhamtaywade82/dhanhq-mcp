# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Order execution tools - actual order placement, modification, cancellation
      class OrdersExecution < Base
        # Place a new order
        #
        # @param args [Hash] order parameters
        # @return [Hash] placed order details
        def place(args)
          order = DhanHQ::Models::Order.place(args)
          return { error: "Order placement failed" } unless order

          serialize_order(order)
        end

        # Modify an existing order
        #
        # @param args [Hash] order_id and modification parameters
        # @return [Hash] modified order details
        def modify(args)
          order_id = args["order_id"]
          return { error: "order_id is required" } unless order_id

          order = DhanHQ::Models::Order.find(order_id)
          return { error: "Order not found" } unless order

          new_params = args.except("order_id")
          result = order.modify(new_params)
          return { error: "Order modification failed" } unless result

          serialize_order(result)
        end

        # Cancel an existing order
        #
        # @param args [Hash] order_id
        # @return [Hash] cancellation result
        def cancel(args)
          order_id = args["order_id"]
          return { error: "order_id is required" } unless order_id

          order = DhanHQ::Models::Order.find(order_id)
          return { error: "Order not found" } unless order

          success = order.cancel
          { success: success, order_id: order_id, status: success ? "CANCELLED" : "FAILED" }
        end

        # Get order by ID
        #
        # @param args [Hash] order_id
        # @return [Hash] order details
        def get(args)
          order_id = args["order_id"]
          return { error: "order_id is required" } unless order_id

          order = DhanHQ::Models::Order.find(order_id)
          return { error: "Order not found" } unless order

          serialize_order(order)
        end

        # Get order by correlation ID
        #
        # @param args [Hash] correlation_id
        # @return [Hash] order details
        def get_by_correlation(args)
          correlation_id = args["correlation_id"]
          return { error: "correlation_id is required" } unless correlation_id

          order = DhanHQ::Models::Order.find_by_correlation(correlation_id)
          return { error: "Order not found" } unless order

          serialize_order(order)
        end

        # Slice order for quantities exceeding freeze limit
        #
        # @param args [Hash] order parameters
        # @return [Array<Hash>] sliced orders
        def slice(args)
          order_id = args["order_id"]
          return { error: "order_id is required" } unless order_id

          order = DhanHQ::Models::Order.find(order_id)
          return { error: "Order not found" } unless order

          new_params = args.except("order_id")
          result = order.slice_order(new_params)
          return { error: "Slice order failed" } unless result

          result.map { |o| serialize_order_hash(o) }
        end

        # Get trades for a specific order
        #
        # @param args [Hash] order_id
        # @return [Array<Hash>] trades for the order
        def get_trades(args)
          order_id = args["order_id"]
          return { error: "order_id is required" } unless order_id

          trade = DhanHQ::Models::Trade.find_by_order_id(order_id)
          return { error: "No trades found" } unless trade

          [serialize_trade(trade)]
        end

        # Get trade history for a date range
        #
        # @param args [Hash] from_date, to_date, page
        # @return [Array<Hash>] historical trades
        def history(args)
          from_date = args["from_date"]
          to_date = args["to_date"]
          page = args["page"] || 0

          return { error: "from_date and to_date are required" } unless from_date && to_date

          trades = DhanHQ::Models::Trade.history(
            from_date: from_date,
            to_date: to_date,
            page: page,
          )

          trades.map { |t| serialize_trade(t) }
        end

        private

        def serialize_order(order)
          {
            order_id: order.order_id,
            order_status: order.order_status,
            correlation_id: order.correlation_id,
            transaction_type: order.transaction_type,
            exchange_segment: order.exchange_segment,
            product_type: order.product_type,
            order_type: order.order_type,
            validity: order.validity,
            trading_symbol: order.trading_symbol,
            security_id: order.security_id,
            quantity: order.quantity,
            disclosed_quantity: order.disclosed_quantity,
            price: order.price,
            trigger_price: order.trigger_price,
            after_market_order: order.after_market_order,
            bo_profit_value: order.bo_profit_value,
            bo_stop_loss_value: order.bo_stop_loss_value,
            leg_name: order.leg_name,
            create_time: order.create_time,
            update_time: order.update_time,
            exchange_time: order.exchange_time,
            drv_expiry_date: order.drv_expiry_date,
            drv_option_type: order.drv_option_type,
            drv_strike_price: order.drv_strike_price,
            oms_error_code: order.oms_error_code,
            oms_error_description: order.oms_error_description,
            algo_id: order.algo_id,
            remaining_quantity: order.remaining_quantity,
            average_traded_price: order.average_traded_price,
            filled_qty: order.filled_qty,
          }.compact
        end

        def serialize_order_hash(order_hash)
          {
            order_id: order_hash[:order_id] || order_hash["orderId"],
            order_status: order_hash[:order_status] || order_hash["orderStatus"],
          }.compact
        end

        def serialize_trade(trade)
          {
            dhan_client_id: trade.dhan_client_id,
            order_id: trade.order_id,
            exchange_order_id: trade.exchange_order_id,
            exchange_trade_id: trade.exchange_trade_id,
            transaction_type: trade.transaction_type,
            exchange_segment: trade.exchange_segment,
            product_type: trade.product_type,
            order_type: trade.order_type,
            trading_symbol: trade.trading_symbol,
            custom_symbol: trade.custom_symbol,
            security_id: trade.security_id,
            traded_quantity: trade.traded_quantity,
            traded_price: trade.traded_price,
            isin: trade.isin,
            instrument: trade.instrument,
            sebi_tax: trade.sebi_tax,
            stt: trade.stt,
            brokerage_charges: trade.brokerage_charges,
            service_tax: trade.service_tax,
            exchange_transaction_charges: trade.exchange_transaction_charges,
            stamp_duty: trade.stamp_duty,
            create_time: trade.create_time,
            update_time: trade.update_time,
            exchange_time: trade.exchange_time,
            drv_expiry_date: trade.drv_expiry_date,
            drv_option_type: trade.drv_option_type,
            drv_strike_price: trade.drv_strike_price,
            total_value: trade.total_value,
            total_charges: trade.total_charges,
            net_value: trade.net_value,
          }.compact
        end
      end
    end
  end
end
