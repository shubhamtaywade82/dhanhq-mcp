# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      module Checks
        class ProductSupport
          def self.run!(args:, instrument:, **_unused)
            product_type = args["product_type"]
            return unless product_type

            enforce_bracket_support!(product_type, instrument)
            enforce_cover_support!(product_type, instrument)
          end

          def self.enforce_bracket_support!(product_type, instrument)
            return unless product_type == "BO"
            return if instrument.bracket_flag == "Y"

            raise Errors::RiskViolation, "Bracket orders not supported"
          end

          def self.enforce_cover_support!(product_type, instrument)
            return unless product_type == "CO"
            return if instrument.cover_flag == "Y"

            raise Errors::RiskViolation, "Cover orders not supported"
          end

          private_class_method :enforce_bracket_support!, :enforce_cover_support!
        end
      end
    end
  end
end
