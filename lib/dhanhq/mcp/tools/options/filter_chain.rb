# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Advanced option chain filtering with multiple criteria
        class FilterChain < Base
          # Filter and sort option chain by multiple criteria
          #
          # @param args [Hash] filtering criteria
          # @return [Array<Hash>] filtered and sorted options
          def call(args)
            chain_data = instrument(args).option_chain(expiry: args["expiry"])
            spot_price = get_spot_price(args)

            options = flatten_chain(chain_data, spot_price)
            filtered = apply_filters(options, args)
            sorted = sort_options(filtered, args)

            build_response(sorted, args)
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

          def flatten_chain(chain_data, spot_price)
            options = []
            chain_oc = chain_data[:oc] || chain_data["oc"] || {}

            chain_oc.each do |strike_str, strike_data|
              strike = strike_str.to_f
              ce_data = strike_data[:ce] || strike_data["ce"]
              pe_data = strike_data[:pe] || strike_data["pe"]

              if ce_data && ce_data[:last_price] && ce_data[:last_price].positive?
                options << build_option(ce_data, strike, "CE", spot_price)
              end

              if pe_data && pe_data[:last_price] && pe_data[:last_price].positive?
                options << build_option(pe_data, strike, "PE", spot_price)
              end
            end

            options
          end

          def build_option(opt_data, strike, option_type, spot_price)
            {
              security_id: opt_data[:security_id] || opt_data["security_id"],
              strike: strike,
              option_type: option_type,
              ltp: opt_data[:last_price] || opt_data["last_price"] || 0,
              oi: opt_data[:oi] || opt_data["oi"] || 0,
              volume: opt_data[:volume] || opt_data["volume"] || 0,
              iv: opt_data[:implied_volatility] || opt_data["implied_volatility"] || 0,
              delta: extract_greek(opt_data, :delta),
              gamma: extract_greek(opt_data, :gamma),
              theta: extract_greek(opt_data, :theta),
              vega: extract_greek(opt_data, :vega),
              distance_from_spot: (strike - spot_price).round(2),
              distance_pct: ((strike - spot_price).abs / spot_price * 100).round(2),
            }
          end

          def extract_greek(opt_data, greek_name)
            greeks = opt_data[:greeks] || opt_data["greeks"] || {}
            greeks[greek_name] || greeks[greek_name.to_s] || 0
          end

          def apply_filters(options, args)
            filters = args["filters"] || {}

            options.select do |opt|
              matches_min_oi?(opt, filters) &&
                matches_min_volume?(opt, filters) &&
                matches_iv_range?(opt, filters) &&
                matches_delta_range?(opt, filters) &&
                matches_premium_range?(opt, filters) &&
                matches_option_type?(opt, filters) &&
                matches_distance?(opt, filters, args)
            end
          end

          def matches_min_oi?(opt, filters)
            return true unless filters["min_oi"]

            opt[:oi] >= filters["min_oi"].to_i
          end

          def matches_min_volume?(opt, filters)
            return true unless filters["min_volume"]

            opt[:volume] >= filters["min_volume"].to_i
          end

          def matches_iv_range?(opt, filters)
            return true unless filters["max_iv"] || filters["min_iv"]

            iv = opt[:iv]
            return false if filters["max_iv"] && iv > filters["max_iv"].to_f
            return false if filters["min_iv"] && iv < filters["min_iv"].to_f

            true
          end

          def matches_delta_range?(opt, filters)
            return true unless filters["min_delta"] || filters["max_delta"]

            delta = opt[:delta].abs
            return false if filters["min_delta"] && delta < filters["min_delta"].to_f
            return false if filters["max_delta"] && delta > filters["max_delta"].to_f

            true
          end

          def matches_premium_range?(opt, filters)
            return true unless filters["premium_range"]

            min_premium, max_premium = filters["premium_range"]
            premium = opt[:ltp]
            premium.between?(min_premium.to_f, max_premium.to_f)
          end

          def matches_option_type?(opt, filters)
            return true unless filters["option_type"]

            opt[:option_type] == filters["option_type"]
          end

          def matches_distance?(opt, filters, _args)
            return true unless filters["max_distance_pct"]

            opt[:distance_pct] <= filters["max_distance_pct"].to_f
          end

          def sort_options(options, args)
            sort_by = args["sort_by"] || "volume"
            limit = args["limit"] || 10

            sorted = case sort_by
                     when "volume"
                       options.sort_by { |opt| -opt[:volume] }
                     when "oi"
                       options.sort_by { |opt| -opt[:oi] }
                     when "premium"
                       options.sort_by { |opt| -opt[:ltp] }
                     when "delta"
                       options.sort_by { |opt| -opt[:delta].abs }
                     when "iv"
                       options.sort_by { |opt| -opt[:iv] }
                     else
                       options
                     end

            sorted.first(limit)
          end

          def build_response(options, _args)
            options.map do |opt|
              {
                security_id: opt[:security_id],
                strike: opt[:strike],
                option_type: opt[:option_type],
                ltp: opt[:ltp],
                oi: opt[:oi],
                volume: opt[:volume],
                iv: opt[:iv],
                delta: opt[:delta],
                gamma: opt[:gamma],
                theta: opt[:theta],
                vega: opt[:vega],
                distance_from_spot: opt[:distance_from_spot],
                distance_pct: opt[:distance_pct],
              }
            end
          end
        end
      end
    end
  end
end
