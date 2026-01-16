# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Fetch option chain for an expiry via Instrument
        class Chain < Base
          # Get option chain data
          #
          # @param args [Hash] exchange_segment, symbol, and expiry
          # @return [Array<Hash>] option chain data
          def call(args)
            instrument(args).option_chain(expiry: args["expiry"])
          end

          private

          def instrument(args)
            DhanHQ::Models::Instrument.find(
              args["exchange_segment"],
              args["symbol"],
            )
          end
        end
      end
    end
  end
end
