# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Trader's control tools - Kill Switch, P&L Exit
      class TradersControl < Base
        # Get kill switch status
        #
        # @return [Hash] kill switch status
        def kill_switch_status
          DhanHQ::Models::KillSwitch.update("DEACTIVATE") # Using update to get status
          # Actually we need a GET for status, but the model doesn't have it
          # Let's use the resource directly
          resource = DhanHQ::Resources::KillSwitch.new
          response = resource.get_status

          normalize_response(response)
        end

        # Activate kill switch
        #
        # @return [Hash] activation result
        def activate_kill_switch
          result = DhanHQ::Models::KillSwitch.activate
          normalize_response(result)
        end

        # Deactivate kill switch
        #
        # @return [Hash] deactivation result
        def deactivate_kill_switch
          result = DhanHQ::Models::KillSwitch.deactivate
          normalize_response(result)
        end

        # Configure P&L based exit
        #
        # @param args [Hash] profit_value, loss_value, product_type, enable_kill_switch
        # @return [Hash] configuration result
        def configure_pnl_exit(args)
          resource = DhanHQ::Resources::PnlExit.new
          response = resource.configure(args)

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, message: response[:message] }
          else
            { success: false, error: response[:errorMessage] || response[:message] || "Failed to configure P&L exit" }
          end
        end

        # Get P&L exit configuration
        #
        # @return [Hash] current P&L exit config
        def pnl_exit
          resource = DhanHQ::Resources::PnlExit.new
          response = resource.get_config

          if response.is_a?(Hash) && response[:status] == "success"
            normalize_keys(response[:data])
          else
            { error: response[:errorMessage] || response[:message] || "Failed to get P&L exit config" }
          end
        end

        # Stop P&L based exit
        #
        # @return [Hash] stop result
        def stop_pnl_exit
          resource = DhanHQ::Resources::PnlExit.new
          response = resource.stop

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, message: response[:message] }
          else
            { success: false, error: response[:errorMessage] || response[:message] || "Failed to stop P&L exit" }
          end
        end

        private

        def normalize_response(response)
          if response.is_a?(Hash)
            if response[:status] == "success" || response[:kill_switch_status]&.include?("successfully")
              { success: true, message: response[:kill_switch_status] || response[:message] }
            else
              { success: false, error: response[:errorMessage] || response[:message] || "Operation failed" }
            end
          else
            { success: false, error: "Invalid response" }
          end
        end

        def normalize_keys(hash)
          hash.transform_keys { |k| k.to_s.underscore.to_sym }
        end
      end
    end
  end
end
