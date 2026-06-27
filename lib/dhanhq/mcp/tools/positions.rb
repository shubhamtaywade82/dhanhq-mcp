# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Position management tools - convert, exit all
      class Positions < Base
        # Convert position between product types
        #
        # @param args [Hash] conversion parameters
        # @return [Hash] conversion result
        def convert(args)
          result = DhanHQ::Models::Position.convert(args)

          if result.is_a?(DhanHQ::ErrorObject)
            { success: false, error: result.errors }
          else
            { success: true, data: result }
          end
        end

        # Exit all open positions
        #
        # @return [Hash] exit result
        def exit_all
          resource = DhanHQ::Resources::Positions.new
          response = resource.exit_all

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, message: "All positions exited" }
          else
            { success: false, error: response[:errorMessage] || response[:message] || "Failed to exit positions" }
          end
        end

        # Get active positions only
        #
        # @return [Array<Hash>] active positions
        def active
          positions = DhanHQ::Models::Position.active
          positions.map { |p| serialize_position(p) }
        end

        private

        def serialize_position(position)
          {
            dhan_client_id: position.dhan_client_id,
            trading_symbol: position.trading_symbol,
            security_id: position.security_id,
            position_type: position.position_type,
            exchange_segment: position.exchange_segment,
            product_type: position.product_type,
            buy_avg: position.buy_avg,
            buy_qty: position.buy_qty,
            cost_price: position.cost_price,
            sell_avg: position.sell_avg,
            sell_qty: position.sell_qty,
            net_qty: position.net_qty,
            realized_profit: position.realized_profit,
            unrealized_profit: position.unrealized_profit,
            rbi_reference_rate: position.rbi_reference_rate,
            multiplier: position.multiplier,
            carry_forward_buy_qty: position.carry_forward_buy_qty,
            carry_forward_sell_qty: position.carry_forward_sell_qty,
            carry_forward_buy_value: position.carry_forward_buy_value,
            carry_forward_sell_value: position.carry_forward_sell_value,
            day_buy_qty: position.day_buy_qty,
            day_sell_qty: position.day_sell_qty,
            day_buy_value: position.day_buy_value,
            day_sell_value: position.day_sell_value,
            drv_expiry_date: position.drv_expiry_date,
            drv_option_type: position.drv_option_type,
            drv_strike_price: position.drv_strike_price,
            cross_currency: position.cross_currency,
          }.compact
        end
      end
    end
  end
end
