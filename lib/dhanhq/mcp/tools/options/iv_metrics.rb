# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Calculate IV percentile and rank
        class IvMetrics < Base
          # Calculate IV metrics for option chain
          #
          # @param args [Hash] option details
          # @return [Hash] IV metrics
          def call(args)
            chain_data = instrument(args).option_chain(expiry: args["expiry"])
            spot_price = get_spot_price(args)

            iv_data = extract_iv_data(chain_data, spot_price)
            atm_iv = calculate_atm_iv(iv_data, spot_price)

            {
              atm_iv: atm_iv.round(2),
              iv_percentile: calculate_iv_percentile(iv_data, atm_iv).round(2),
              iv_rank: calculate_iv_rank(iv_data, atm_iv).round(2),
              iv_min: iv_data.min.round(2),
              iv_max: iv_data.max.round(2),
              iv_avg: (iv_data.sum / iv_data.length).round(2),
              recommendation: generate_recommendation(atm_iv, iv_data),
            }
          end

          private

          def instrument(args)
            DhanHQ::Models::Instrument.find(
              args["exchange_segment"],
              args["symbol"],
            )
          end

          def get_spot_price(args)
            return args["spot_price"].to_f if args["spot_price"]

            instrument(args).ltp[:ltp] || instrument(args).ltp["ltp"] || 0
          end

          def extract_iv_data(chain_data, spot_price)
            iv_values = []
            chain_oc = chain_data[:oc] || chain_data["oc"] || {}

            chain_oc.each do |strike_str, strike_data|
              strike = strike_str.to_f
              # Focus on strikes near ATM (within 5% of spot)
              next unless (strike - spot_price).abs / spot_price <= 0.05

              [strike_data[:ce] || strike_data["ce"], strike_data[:pe] || strike_data["pe"]].each do |opt_data|
                next unless opt_data

                iv = opt_data[:implied_volatility] || opt_data["implied_volatility"]
                iv_values << iv if iv&.positive?
              end
            end

            iv_values.empty? ? [20.0] : iv_values
          end

          def calculate_atm_iv(iv_data, _spot_price)
            # Use median of IV values as ATM IV
            sorted = iv_data.sort
            mid = sorted.length / 2
            sorted.length.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
          end

          def calculate_iv_percentile(iv_data, current_iv)
            return 50.0 if iv_data.empty?

            sorted = iv_data.sort
            below_count = sorted.count { |iv| iv < current_iv }
            (below_count.to_f / sorted.length * 100)
          end

          def calculate_iv_rank(iv_data, current_iv)
            return 50.0 if iv_data.empty?

            sorted = iv_data.sort
            min_iv = sorted.first
            max_iv = sorted.last
            return 50.0 if max_iv == min_iv

            ((current_iv - min_iv) / (max_iv - min_iv) * 100)
          end

          def generate_recommendation(atm_iv, iv_data)
            percentile = calculate_iv_percentile(iv_data, atm_iv)

            case percentile
            when 0.0..25.0
              "IV is LOW - Good time to BUY options (cheap volatility)"
            when 25.0..50.0
              "IV is MODERATE - Neutral for buying options"
            when 50.0..75.0
              "IV is HIGH - Consider waiting or selling premium"
            else
              "IV is VERY HIGH - Expensive options, consider selling strategies"
            end
          end
        end
      end
    end
  end
end
