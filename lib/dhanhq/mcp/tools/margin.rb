# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Margin calculator tools - single and multi-order
      class Margin < Base
        # Calculate margin for a single order
        #
        # @param args [Hash] order parameters for margin calculation
        # @return [Hash] margin calculation result
        def calculate(args)
          margin = DhanHQ::Models::Margin.calculate(args)
          return { error: "Margin calculation failed" } unless margin

          margin.to_h
        end

        # Calculate margin for multiple orders
        #
        # @param args [Hash] dhan_client_id, include_position, include_order, scrip_list
        # @return [Hash] multi-order margin calculation result
        def calculate_multi(args)
          resource = DhanHQ::Resources::MarginCalculator.new
          response = resource.calculate_multi(args)

          if response.is_a?(Hash) && response[:status] == "success"
            normalize_keys(response[:data])
          else
            { error: response[:errorMessage] || response[:message] || "Failed to calculate multi-order margin" }
          end
        end

        private

        def normalize_keys(hash)
          hash.transform_keys { |k| k.to_s.underscore.to_sym }
        end
      end
    end
  end
end
