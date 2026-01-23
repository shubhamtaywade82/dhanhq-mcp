# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      module Checks
        class AsmGsm
          def self.run!(instrument:, **_unused)
            return unless instrument.asm_gsm_flag == "Y"

            raise Errors::RiskViolation,
                  "ASM/GSM restricted instrument (#{instrument.asm_gsm_category})"
          end
        end
      end
    end
  end
end
