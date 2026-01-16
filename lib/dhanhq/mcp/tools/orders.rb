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
          inst = load_instrument(args)

          enforce_compliance!(inst)
          validate_quantity!(args)
          validate_risk!(args)

          build_intent(inst, args)
        end

        private

        def load_instrument(args)
          DhanHQ::Models::Instrument.find(
            args["exchange_segment"],
            args["symbol"],
          )
        end

        def enforce_compliance!(inst)
          check_trading_allowed!(inst)
          check_asm_gsm!(inst)
          check_product_support!(inst)
        end

        def check_trading_allowed!(inst)
          return if inst.buy_sell_indicator == "A"

          raise Errors::RiskViolation, "Trading disabled for instrument"
        end

        def check_asm_gsm!(inst)
          return unless inst.asm_gsm_flag == "Y"

          raise Errors::RiskViolation, "ASM/GSM restricted"
        end

        def check_product_support!(inst)
          return if inst.instrument_type != "INDEX"

          raise Errors::RiskViolation, "Use option.prepare for index options"
        end

        def validate_quantity!(args)
          return if args["quantity"].to_i.positive?

          raise Errors::RiskViolation, "Invalid quantity"
        end

        def validate_risk!(args)
          check_stop_loss!(args) if args["stop_loss"]
          check_target!(args) if args["target"]
          check_rr_ratio!(args) if args["stop_loss"] && args["target"]
        end

        def check_stop_loss!(args)
          return if args["stop_loss"].to_f.positive?

          raise Errors::RiskViolation, "Invalid stop loss"
        end

        def check_target!(args)
          return if args["target"].to_f.positive?

          raise Errors::RiskViolation, "Invalid target"
        end

        def check_rr_ratio!(args)
          return if valid_rr?(args)

          raise Errors::RiskViolation, "Bad risk-reward ratio"
        end

        def valid_rr?(args)
          if args["transaction_type"] == "BUY"
            args["target"] > args["stop_loss"]
          else
            args["stop_loss"] > args["target"]
          end
        end

        def build_intent(inst, args)
          base_intent(inst, args).merge(risk_params(args))
        end

        def base_intent(inst, args)
          {
            trade_type: "EQUITY_FUTURES",
            instrument: instrument_name(inst),
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

        def instrument_name(inst)
          "#{inst.symbol_name} (#{inst.exchange_segment})"
        end

        def confirmation_note
          "Prepared trade intent. Await human confirmation."
        end
      end
    end
  end
end
