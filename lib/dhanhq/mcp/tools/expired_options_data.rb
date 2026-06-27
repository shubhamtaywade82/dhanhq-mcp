# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Historical rolling options data tool
      class ExpiredOptionsData < Base
        # Get historical rolling options data
        #
        # @param args [Hash] exchange_segment, interval, security_id, instrument, expiry_flag, expiry_code, strike, drv_option_type, required_data, from_date, to_date
        # @return [Hash] expired options data
        def get(args)
          resource = DhanHQ::Resources::ExpiredOptionsData.new
          response = resource.fetch(args)

          if response.is_a?(Hash) && response[:status] == "success"
            normalize_keys(response[:data])
          else
            { error: response[:errorMessage] || response[:message] || "Failed to get expired options data" }
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
