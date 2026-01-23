# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Prepare equity/futures trade intent (no execution)
      class Orders < Base
        # Build trade intent with compliance checks
        #
        # @param args [Hash] trade parameters
        # @return [Hash] prepared trade intent
        # @raise [Errors::RiskViolation] on compliance failure
        def prepare(args)
          instrument = load_instrument(args)

          Risk::Pipeline.run!(
            context: context,
            args: args,
            instrument: instrument,
            type: :equity,
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
          base_intent(instrument, args).merge(risk_params(args))
        end

        def base_intent(instrument, args)
          {
            trade_type: "EQUITY_FUTURES",
            instrument: instrument_name(instrument),
            transaction_type: args["transaction_type"],
            quantity: args["quantity"],
            order_type: args["order_type"],
            product_type: args["product_type"],
          }
        end

        def risk_params(args)
          {
            price: args["price"],
            stop_loss: args["stop_loss"],
            target: args["target"],
            note: confirmation_note,
          }
        end

        def instrument_name(instrument)
          "#{instrument.symbol_name} (#{instrument.exchange_segment})"
        end

        def confirmation_note
          "Prepared trade intent. Await human confirmation."
        end
      end
    end
  end
end
