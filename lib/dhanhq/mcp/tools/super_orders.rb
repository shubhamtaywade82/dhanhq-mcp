# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Super order execution tools - place, modify, cancel legs, get all
      class SuperOrders < Base
        # Place a new super order (bracket order)
        #
        # @param args [Hash] super order parameters
        # @return [Hash] placed super order details
        def place(args)
          order = DhanHQ::Models::SuperOrder.create(args)
          return { error: "Super order placement failed" } unless order

          serialize_super_order(order)
        end

        # Modify a super order leg
        #
        # @param args [Hash] order_id, leg_name, and modification parameters
        # @return [Hash] modification result
        def modify(args)
          order_id = args["order_id"]
          return { error: "order_id is required" } unless order_id

          order = DhanHQ::Models::SuperOrder.all.find { |o| o.order_id == order_id }
          return { error: "Super order not found" } unless order

          new_params = args.except("order_id")
          success = order.modify(new_params)
          { success: success, order_id: order_id }
        end

        # Cancel a specific leg of a super order
        #
        # @param args [Hash] order_id, leg_name
        # @return [Hash] cancellation result
        def cancel_leg(args)
          order_id = args["order_id"]
          leg_name = args["leg_name"] || "ENTRY_LEG"
          return { error: "order_id is required" } unless order_id

          order = DhanHQ::Models::SuperOrder.all.find { |o| o.order_id == order_id }
          return { error: "Super order not found" } unless order

          success = order.cancel(leg_name)
          { success: success, order_id: order_id, leg_name: leg_name, status: success ? "CANCELLED" : "FAILED" }
        end

        # Get all super orders
        #
        # @return [Array<Hash>] super orders
        def all
          orders = DhanHQ::Models::SuperOrder.all
          orders.map { |o| serialize_super_order(o) }
        end

        # Get super order by ID
        #
        # @param args [Hash] order_id
        # @return [Hash] super order details
        def get(args)
          order_id = args["order_id"]
          return { error: "order_id is required" } unless order_id

          order = DhanHQ::Models::SuperOrder.all.find { |o| o.order_id == order_id }
          return { error: "Super order not found" } unless order

          serialize_super_order(order)
        end

        private

        def serialize_super_order(order)
          {
            dhan_client_id: order.dhan_client_id,
            order_id: order.order_id,
            correlation_id: order.correlation_id,
            order_status: order.order_status,
            transaction_type: order.transaction_type,
            exchange_segment: order.exchange_segment,
            product_type: order.product_type,
            order_type: order.order_type,
            validity: order.validity,
            trading_symbol: order.trading_symbol,
            security_id: order.security_id,
            quantity: order.quantity,
            remaining_quantity: order.remaining_quantity,
            ltp: order.ltp,
            price: order.price,
            after_market_order: order.after_market_order,
            leg_name: order.leg_name,
            exchange_order_id: order.exchange_order_id,
            create_time: order.create_time,
            update_time: order.update_time,
            exchange_time: order.exchange_time,
            oms_error_description: order.oms_error_description,
            average_traded_price: order.average_traded_price,
            filled_qty: order.filled_qty,
            leg_details: order.leg_details,
            target_price: order.target_price,
            stop_loss_price: order.stop_loss_price,
            trailing_jump: order.trailing_jump,
          }.compact
        end
      end
    end
  end
end
