# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Calculate risk-reward metrics for option trades
        class RiskReward < Base
          # Calculate max profit, max loss, breakeven, risk-reward ratio
          #
          # @param args [Hash] option details
          # @return [Hash] risk-reward metrics
          def call(args)
            strike = args["strike"].to_f
            option_type = args["option_type"]
            premium = args["premium"].to_f
            quantity = args["quantity"].to_i
            spot_price = get_spot_price(args)

            max_profit = calculate_max_profit(strike, option_type, premium, quantity, spot_price)
            max_loss = calculate_max_loss(premium, quantity)
            breakeven = calculate_breakeven(strike, option_type, premium)
            risk_reward_ratio = calculate_risk_reward_ratio(max_profit, max_loss)

            {
              strike: strike,
              option_type: option_type,
              premium: premium,
              quantity: quantity,
              spot_price: spot_price,
              max_profit: max_profit.round(2),
              max_loss: max_loss.round(2),
              breakeven: breakeven.round(2),
              risk_reward_ratio: risk_reward_ratio.round(2),
              intrinsic_value: calculate_intrinsic_value(strike, option_type, spot_price).round(2),
              time_value: (premium - calculate_intrinsic_value(strike, option_type, spot_price)).round(2),
            }
          end

          private

          def get_spot_price(args)
            return args["spot_price"].to_f if args["spot_price"]

            instrument(args).ltp[:ltp] || instrument(args).ltp["ltp"] || 0
          end

          def instrument(args)
            DhanHQ::Models::Instrument.find(
              args["exchange_segment"],
              args["symbol"],
            )
          end

          def calculate_max_profit(_strike, option_type, premium, quantity, _spot_price)
            # For long options: unlimited profit potential (simplified to large number)
            # In practice, calculate based on expected move or target
            if option_type == "CE"
              # Call option: profit if spot > breakeven
              # Simplified: assume 2x premium as reasonable target
            else
              # Put option: profit if spot < breakeven
              # Simplified: assume 2x premium as reasonable target
            end
            (premium * 2 * quantity).round(2)
          end

          def calculate_max_loss(premium, quantity)
            # For long options: max loss is premium paid
            (premium * quantity).round(2)
          end

          def calculate_breakeven(strike, option_type, premium)
            if option_type == "CE"
              # Call: breakeven = strike + premium
              strike + premium
            else
              # Put: breakeven = strike - premium
              strike - premium
            end
          end

          def calculate_risk_reward_ratio(max_profit, max_loss)
            return 0 if max_loss.zero?

            (max_profit / max_loss).round(2)
          end

          def calculate_intrinsic_value(strike, option_type, spot_price)
            if option_type == "CE"
              # Call: intrinsic = max(0, spot - strike)
              [spot_price - strike, 0].max
            else
              # Put: intrinsic = max(0, strike - spot)
              [strike - spot_price, 0].max
            end
          end
        end
      end
    end
  end
end
