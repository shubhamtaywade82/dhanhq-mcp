# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      module Checks
        class TradingPermission
          def self.run!(instrument:, **_unused)
            return if instrument.buy_sell_indicator == "A"

            raise Errors::RiskViolation, "Trading disabled for instrument"
          end
        end
      end
    end
  end
end
