# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      module Checks
        class Options
          def self.run!(args:, instrument:, **_unused)
            enforce_index!(instrument)
            enforce_stop_loss!(args)
            enforce_target!(args)
            enforce_risk_reward!(args)
          end

          def self.enforce_index!(instrument)
            return if instrument.instrument_type == "INDEX"

            raise Errors::RiskViolation, "Options only allowed on index"
          end

          def self.enforce_stop_loss!(args)
            return if args["stop_loss"]

            raise Errors::RiskViolation, "Stop loss required"
          end

          def self.enforce_target!(args)
            return if args["target"]

            raise Errors::RiskViolation, "Target required"
          end

          def self.enforce_risk_reward!(args)
            stop_loss = args["stop_loss"]
            target = args["target"]
            return if target > stop_loss

            raise Errors::RiskViolation, "Invalid risk-reward"
          end

          private_class_method :enforce_index!, :enforce_stop_loss!,
                               :enforce_target!, :enforce_risk_reward!
        end
      end
    end
  end
end
