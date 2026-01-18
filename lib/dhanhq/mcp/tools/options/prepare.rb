# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Options
        # Prepare an OPTIONS BUY trade intent (no execution)
        class Prepare < Base
          # Build trade intent with compliance checks
          #
          # @param args [Hash] trade parameters
          # @return [Hash] prepared trade intent
          # @raise [Errors::RiskViolation] on compliance failure
          def call(args)
            instrument = load_instrument(args)

            Risk::Pipeline.run!(
              context: context,
              args: args,
              instrument: instrument,
              type: :options,
            )

            build_intent(instrument, args)
          end

          private

          def load_instrument(args)
            DhanHQ::Models::Instrument.find(
              args["exchange_segment"],
              args["symbol"],
            )
          end

          def build_intent(instrument, args)
            {
              trade_type: "OPTIONS_BUY",
              instrument: build_name(instrument, args),
              security_id: args["security_id"],
              expiry: args["expiry"],
              quantity: args["quantity"],
              stop_loss: args["stop_loss"],
              target: args["target"],
              note: "Prepared options BUY trade. Await human confirmation.",
            }
          end

          def build_name(instrument, args)
            "#{instrument.symbol_name} #{args["strike"]} #{args["option_type"]}"
          end
        end
      end
    end
  end
end
