# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      class Pipeline
        CHECKS = [
          Checks::TradingPermission,
          Checks::AsmGsm,
          Checks::ProductSupport,
          Checks::OrderType,
          Checks::Quantity,
          Checks::MarketHours,
        ].freeze

        OPTION_CHECKS = [
          Checks::Options,
        ].freeze

        def self.run!(context:, args:, instrument:, type:)
          run_checks!(CHECKS, context, args, instrument)
          run_checks!(OPTION_CHECKS, context, args, instrument) if type == :options
          true
        end

        def self.run_checks!(checks, context, args, instrument)
          checks.each do |check|
            check.run!(context: context, args: args, instrument: instrument)
          end
        end

        private_class_method :run_checks!
      end
    end
  end
end
