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
            inst = instrument(args)

            enforce_compliance!(inst)
            validate_risk_reward!(args)

            build_intent(inst, args)
          end

          private

          def instrument(args)
            DhanHQ::Models::Instrument.find(
              args["exchange_segment"],
              args["symbol"],
            )
          end

          def enforce_compliance!(inst)
            check_trading_allowed!(inst)
            check_asm_gsm!(inst)
            check_instrument_type!(inst)
          end

          def check_trading_allowed!(inst)
            return if inst.buy_sell_indicator == "A"

            raise Errors::RiskViolation, "Trading disabled for instrument"
          end

          def check_asm_gsm!(inst)
            return unless inst.asm_gsm_flag == "Y"

            raise Errors::RiskViolation, "ASM/GSM restricted"
          end

          def check_instrument_type!(inst)
            return if inst.instrument_type == "INDEX"

            raise Errors::RiskViolation, "Options not supported"
          end

          def validate_risk_reward!(args)
            check_stop_loss!(args)
            check_target!(args)
            check_rr_ratio!(args)
          end

          def check_stop_loss!(args)
            return if args["stop_loss"]

            raise Errors::RiskViolation, "Stop loss required"
          end

          def check_target!(args)
            return if args["target"]

            raise Errors::RiskViolation, "Target required"
          end

          def check_rr_ratio!(args)
            return if args["target"] > args["stop_loss"]

            raise Errors::RiskViolation, "Bad risk-reward"
          end

          def build_intent(inst, args)
            {
              trade_type: "OPTIONS_BUY",
              instrument: build_name(inst, args),
              security_id: args["security_id"],
              expiry: args["expiry"],
              quantity: args["quantity"],
              stop_loss: args["stop_loss"],
              target: args["target"],
              note: "Prepared options BUY trade. Await human confirmation.",
            }
          end

          def build_name(inst, args)
            "#{inst.symbol} #{args["strike"]} #{args["option_type"]}"
          end
        end
      end
    end
  end
end
