# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Get available option expiries for an index instrument
        class Expiries < Base
          # Fetch expiry list via Instrument
          #
          # @param args [Hash] exchange_segment and symbol
          # @return [Array<String>] list of expiry dates
          def call(args)
            instrument(args).expiry_list
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
