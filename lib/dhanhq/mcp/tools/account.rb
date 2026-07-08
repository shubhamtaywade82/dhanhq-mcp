# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Account management tools - static IP whitelisting (GET/POST/PUT /v2/ip) and user profile.
      # The client returns raw response hashes and raises DhanHQ::Error on failure,
      # so tools normalize keys on success and surface error messages on rescue.
      class Account < Base
        # rubocop:disable Naming/AccessorMethodName -- names mirror the DhanHQ getIP/setIP endpoints
        # Get configured static IP addresses
        #
        # @return [Hash] primary/secondary IPs and their modify-from dates
        def get_ip
          response = DhanHQ::Resources::IPSetup.new.current
          normalize_keys(response)
        rescue DhanHQ::Error => e
          { error: e.message }
        end

        # Set a static IP address
        #
        # @param args [Hash] dhan_client_id, ip, ip_flag (PRIMARY | SECONDARY)
        # @return [Hash] set IP result
        def set_ip(args)
          response = DhanHQ::Resources::IPSetup.new.set(
            ip: args["ip"],
            ip_flag: args["ip_flag"] || "PRIMARY",
            dhan_client_id: args["dhan_client_id"],
          )
          { success: true }.merge(normalize_keys(response))
        rescue DhanHQ::Error => e
          { success: false, error: e.message }
        end
        # rubocop:enable Naming/AccessorMethodName

        # Modify a whitelisted static IP address
        #
        # @param args [Hash] dhan_client_id, ip, ip_flag (PRIMARY | SECONDARY)
        # @return [Hash] modify IP result
        def modify_ip(args)
          response = DhanHQ::Resources::IPSetup.new.update(
            ip: args["ip"],
            ip_flag: args["ip_flag"] || "PRIMARY",
            dhan_client_id: args["dhan_client_id"],
          )
          { success: true }.merge(normalize_keys(response))
        rescue DhanHQ::Error => e
          { success: false, error: e.message }
        end

        # Get user profile
        #
        # @return [Hash] user profile
        def profile
          response = DhanHQ::Resources::Profile.new.fetch
          normalize_keys(response)
        rescue DhanHQ::Error => e
          { error: e.message }
        end

        private

        def normalize_keys(response)
          return {} unless response.is_a?(Hash)

          response.transform_keys { |k| k.to_s.underscore.to_sym }
        end
      end
    end
  end
end
