# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Rule-based CE/PE strike selection (no prediction)
        class Selector < Base
          # Select strikes based on rules
          #
          # @param args [Hash] selection criteria
          # @return [Array<Hash>] top 3 ranked strikes
          def call(args)
            chain = instrument(args).option_chain(expiry: args["expiry"])

            filtered = filter_chain(chain, args)
            ranked = rank_by_distance(filtered, args)

            build_response(ranked)
          end

          private

          def instrument(args)
            DhanHQ::Models::Instrument.find(
              args["exchange_segment"],
              args["symbol"],
            )
          end

          def filter_chain(chain, args)
            chain.select do |opt|
              correct_side?(opt, args) &&
                within_distance?(opt, args) &&
                premium_ok?(opt, args)
            end
          end

          def rank_by_distance(filtered, args)
            filtered.sort_by do |opt|
              (opt.strike - args["spot_price"]).abs
            end
          end

          def build_response(ranked)
            ranked.first(3).map do |opt|
              {
                security_id: opt.security_id,
                strike: opt.strike,
                option_type: opt.option_type,
                ltp: opt.ltp,
                distance_from_spot: distance(opt),
              }
            end
          end

          def distance(opt)
            (opt.strike - context.meta[:spot_price]).round(2)
          end

          def correct_side?(opt, args)
            opt.option_type == (args["direction"] == "BULLISH" ? "CE" : "PE")
          end

          def within_distance?(opt, args)
            pct = calculate_distance_pct(opt, args)
            pct <= max_distance_pct(args)
          end

          def calculate_distance_pct(opt, args)
            ((opt.strike - args["spot_price"]).abs / args["spot_price"]) * 100
          end

          def max_distance_pct(args)
            args.fetch("max_distance_pct", 1.0).to_f
          end

          def premium_ok?(opt, args)
            opt.ltp.between?(min_premium(args), max_premium(args))
          end

          def min_premium(args)
            args.fetch("min_premium", 50).to_f
          end

          def max_premium(args)
            args.fetch("max_premium", 300).to_f
          end
        end
      end
    end
  end
end
