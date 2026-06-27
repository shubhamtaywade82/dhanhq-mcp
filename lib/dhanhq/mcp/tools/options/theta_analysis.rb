# frozen_string_literal: true

require "date"

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Analyze theta decay over time
        class ThetaAnalysis < Base
          # Show how premium decays over remaining days
          #
          # @param args [Hash] option details
          # @return [Hash] theta decay analysis
          def call(args)
            strike = args["strike"].to_f
            option_type = args["option_type"]
            current_premium = args["premium"].to_f
            expiry = args["expiry"]
            get_spot_price(args)
            args["iv"] || get_iv_from_chain(args, strike, option_type)

            days_to_expiry = calculate_days_to_expiry(expiry)
            current_theta = get_current_theta(args, strike, option_type)

            decay_projection = project_decay(
              current_premium,
              current_theta,
              days_to_expiry,
              args["days_ahead"] || [days_to_expiry, days_to_expiry - 1, days_to_expiry - 2, 1, 0].select do |d|
                d >= 0
              end,
            )

            {
              strike: strike,
              option_type: option_type,
              current_premium: current_premium.round(2),
              days_to_expiry: days_to_expiry,
              current_theta: current_theta.round(2),
              daily_decay_avg: current_theta.abs.round(2),
              decay_projection: decay_projection,
              warning: days_to_expiry <= 3 ? "High time decay risk - consider exiting early" : nil,
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

            opt_data = option_type == "CE" ? (strike_data[:ce] || strike_data["ce"]) : (strike_data[:pe] || strike_data["pe"])
            return 0.2 unless opt_data

            (opt_data[:implied_volatility] || opt_data["implied_volatility"] || 0.2) / 100.0
          end

          def get_current_theta(args, strike, option_type)
            chain_data = instrument(args).option_chain(expiry: args["expiry"])
            chain_oc = chain_data[:oc] || chain_data["oc"] || {}
            strike_data = chain_oc[strike.to_s] || chain_oc[strike.to_f.to_s]

            return -10.0 unless strike_data

            opt_data = option_type == "CE" ? (strike_data[:ce] || strike_data["ce"]) : (strike_data[:pe] || strike_data["pe"])
            return -10.0 unless opt_data

            greeks = opt_data[:greeks] || opt_data["greeks"] || {}
            -(greeks[:theta] || greeks["theta"] || 10.0)
          end

          def calculate_days_to_expiry(expiry_str)
            return 7 unless expiry_str

            expiry_date = Date.parse(expiry_str)
            (expiry_date - Date.today).to_i
          end

          def project_decay(current_premium, current_theta, days_to_expiry, days_ahead)
            days_ahead.map do |days_remaining|
              days_passed = days_to_expiry - days_remaining
              # Theta decay accelerates as expiry approaches
              # Simplified model: linear decay with acceleration factor
              acceleration = if days_remaining <= 1
                               2.0
                             else
                               (days_remaining <= 3 ? 1.5 : 1.0)
                             end
              decay_amount = current_theta.abs * days_passed * acceleration
              projected_premium = [current_premium - decay_amount, 0].max

              {
                days_remaining: days_remaining,
                projected_premium: projected_premium.round(2),
                decay_amount: decay_amount.round(2),
                decay_pct: ((decay_amount / current_premium) * 100).round(2),
              }
            end
          end
        end
      end
    end
  end
end
