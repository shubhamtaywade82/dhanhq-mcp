# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      module Checks
        class OrderType
          VALID_TYPES = %w[MARKET LIMIT].freeze

          def self.run!(args:, **_unused)
            order_type = args["order_type"]
            return unless order_type
            return if VALID_TYPES.include?(order_type)

            raise Errors::RiskViolation, "Invalid order type"
          end
        end
      end
    end
  end
end
