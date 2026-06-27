# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Conditional trigger tools - place, modify, delete, get all, get by ID
      class ConditionalTriggers < Base
        # Place a new conditional trigger
        #
        # @param args [Hash] conditional trigger parameters
        # @return [Hash] created conditional trigger details
        def place(args)
          # The DhanHQ client doesn't have a ConditionalTrigger model yet
          # We'll use the resource directly
          resource = DhanHQ::Resources::ConditionalTriggers.new
          response = resource.create(args)

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, alert_id: response[:data]["alertId"] || response[:data]["alert_id"],
              data: response[:data] }
          else
            { success: false,
              error: response[:errorMessage] || response[:message] || "Failed to create conditional trigger" }
          end
        end

        # Modify an existing conditional trigger
        #
        # @param args [Hash] alert_id and modification parameters
        # @return [Hash] modification result
        def modify(args)
          alert_id = args["alert_id"]
          return { error: "alert_id is required" } unless alert_id

          resource = DhanHQ::Resources::ConditionalTriggers.new
          response = resource.update(alert_id, args)

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, data: response[:data] }
          else
            { success: false,
              error: response[:errorMessage] || response[:message] || "Failed to modify conditional trigger" }
          end
        end

        # Delete a conditional trigger
        #
        # @param args [Hash] alert_id
        # @return [Hash] deletion result
        def delete(args)
          alert_id = args["alert_id"]
          return { error: "alert_id is required" } unless alert_id

          resource = DhanHQ::Resources::ConditionalTriggers.new
          response = resource.delete(alert_id)

          if response.is_a?(Hash) && response[:status] == "success"
            { success: true, alert_id: alert_id }
          else
            { success: false,
              error: response[:errorMessage] || response[:message] || "Failed to delete conditional trigger" }
          end
        end

        # Get all conditional triggers
        #
        # @return [Array<Hash>] conditional triggers
        def all
          resource = DhanHQ::Resources::ConditionalTriggers.new
          response = resource.all

          if response.is_a?(Array)
            response.map { |t| normalize_keys(t) }
          else
            []
          end
        end

        # Get conditional trigger by ID
        #
        # @param args [Hash] alert_id
        # @return [Hash] conditional trigger details
        def get(args)
          alert_id = args["alert_id"]
          return { error: "alert_id is required" } unless alert_id

          resource = DhanHQ::Resources::ConditionalTriggers.new
          response = resource.find(alert_id)

          if response.is_a?(Hash)
            normalize_keys(response)
          else
            { error: "Conditional trigger not found" }
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
