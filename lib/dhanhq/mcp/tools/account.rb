# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Account management tools - IP, profile
      class Account < Base
        # Get configured IP addresses
        #
        # @return [Hash] IP configuration
        def ip
          resource = DhanHQ::Resources::IP.new
          response = resource.get_ip

          if response.is_a?(Hash) && response[:status] == "success"
            normalize_keys(response[:data])
          else
            { error: response[:errorMessage] || response[:message] || "Failed to get IP" }
          end
        end

        # Set IP address
        #
        # @param args [Hash] dhan_client_id, ip, ip_flag
        # @return [Hash] set IP result
        def ip=(args)
          resource = DhanHQ::Resources::IP.new
          response = resource.set_ip(args)

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, message: response[:message] }
          else
            { success: false, error: response[:errorMessage] || response[:message] || "Failed to set IP" }
          end
        end

        # Modify IP address
        #
        # @param args [Hash] dhan_client_id, ip, ip_flag
        # @return [Hash] modify IP result
        def modify_ip(args)
          resource = DhanHQ::Resources::IP.new
          response = resource.modify_ip(args)

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, message: response[:message] }
          else
            { success: false, error: response[:errorMessage] || response[:message] || "Failed to modify IP" }
          end
        end

        # Get user profile
        #
        # @return [Hash] user profile
        def profile
          resource = DhanHQ::Resources::Profile.new
          response = resource.fetch

          if response.is_a?(Hash) && response[:status] == "success"
            normalize_keys(response[:data])
          else
            { error: response[:errorMessage] || response[:message] || "Failed to get profile" }
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
