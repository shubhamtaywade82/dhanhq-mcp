# frozen_string_literal: true

require "date"

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Calculate probability metrics for option trades
        class Probability < Base
          # Calculate probability of profit, ITM, breakeven
          #
          # @param args [Hash] option details
          # @return [Hash] probability metrics
          def call(args)
            strike = args["strike"].to_f
            option_type = args["option_type"]
            premium = args["premium"].to_f
            spot_price = get_spot_price(args)
            implied_volatility = args["iv"] || get_iv_from_chain(args, strike, option_type)
            days_to_expiry = calculate_days_to_expiry(args["expiry"])

            breakeven = calculate_breakeven(strike, option_type, premium)
            prob_itm = calculate_probability_itm(
              strike,
              option_type,
              spot_price,
              implied_volatility,
              days_to_expiry,
            )
            prob_profit = calculate_probability_profit(
              breakeven,
              option_type,
              spot_price,
              implied_volatility,
              days_to_expiry,
            )
            prob_otm = 1.0 - prob_itm

            {
              strike: strike,
              option_type: option_type,
              premium: premium,
              spot_price: spot_price,
              iv: implied_volatility,
              days_to_expiry: days_to_expiry,
              breakeven: breakeven.round(2),
              prob_itm: (prob_itm * 100).round(2),
              prob_otm: (prob_otm * 100).round(2),
              prob_profit: (prob_profit * 100).round(2),
              interpretation: interpret_probability(prob_profit),
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

          def get_iv_from_chain(args, strike, option_type)
            chain_data = instrument(args).option_chain(expiry: args["expiry"])
            chain_oc = chain_data[:oc] || chain_data["oc"] || {}
            strike_data = chain_oc[strike.to_s] || chain_oc[strike.to_f.to_s]

            return 0.2 unless strike_data

            opt_data = if option_type == "CE"
                         strike_data[:ce] || strike_data["ce"]
                       else
                         strike_data[:pe] || strike_data["pe"]
                       end
            return 0.2 unless opt_data

            (opt_data[:implied_volatility] || opt_data["implied_volatility"] || 0.2) / 100.0
          end

          def calculate_days_to_expiry(expiry_str)
            return 7 unless expiry_str

            expiry_date = Date.parse(expiry_str)
            (expiry_date - Date.today).to_i
          end

          def calculate_breakeven(strike, option_type, premium)
            if option_type == "CE"
              strike + premium
            else
              strike - premium
            end
          end

          def calculate_probability_itm(strike, option_type, spot_price, implied_volatility, days_to_expiry)
            # Simplified Black-Scholes probability calculation
            # Using normal distribution approximation
            return 0.5 if implied_volatility.zero? || days_to_expiry <= 0

            d2 = calculate_d2(strike, spot_price, implied_volatility, days_to_expiry)
            if option_type == "CE"
              # Probability spot > strike at expiry
              normal_cdf(d2)
            else
              # Probability spot < strike at expiry
              1.0 - normal_cdf(d2)
            end
          end

          def calculate_probability_profit(
            breakeven,
            option_type,
            spot_price,
            implied_volatility,
            days_to_expiry
          )
            # Probability of reaching breakeven
            return 0.5 if implied_volatility.zero? || days_to_expiry <= 0

            d2 = calculate_d2(breakeven, spot_price, implied_volatility, days_to_expiry)
            if option_type == "CE"
              # Probability spot > breakeven
              normal_cdf(d2)
            else
              # Probability spot < breakeven
              1.0 - normal_cdf(d2)
            end
          end

          def calculate_d2(strike, spot_price, implied_volatility, days_to_expiry)
            # Black-Scholes d2 calculation (simplified)
            time_years = days_to_expiry / 365.0
            return 0 if time_years <= 0

            log_s_k = Math.log(spot_price / strike)
            vol_sqrt_t = implied_volatility * Math.sqrt(time_years)

            return 0 if vol_sqrt_t.zero?

            (log_s_k / vol_sqrt_t) - (vol_sqrt_t / 2.0)
          end

          def normal_cdf(value)
            # Approximation of standard normal CDF
            # Using error function approximation
            0.5 * (1 + Math.erf(value / Math.sqrt(2)))
          end

          def interpret_probability(prob)
            case prob
            when 0.0..0.3
              "LOW - High risk trade"
            when 0.3..0.5
              "MODERATE - Balanced risk"
            when 0.5..0.7
              "GOOD - Favorable odds"
            else
              "HIGH - Strong probability"
            end
          end
        end
      end
    end
  end
end
