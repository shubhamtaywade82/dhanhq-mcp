# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Conditional trigger (alert order) tools - place, modify, delete, get all, get by ID.
      # Backed by DhanHQ::Models::AlertOrder (POST/PUT/DELETE/GET /v2/alerts/orders),
      # which validates payloads via AlertOrderContract and requires LIVE_TRADING for writes.
      class ConditionalTriggers < Base
        # Place a new conditional trigger
        #
        # @param args [Hash] condition + orders payload
        # @return [Hash] created conditional trigger details
        def place(args)
          alert = DhanHQ::Models::AlertOrder.create(args)
          return { success: false, error: "Failed to create conditional trigger" } unless alert

          { success: true, alert_id: alert.id }.merge(serialize_alert(alert))
        rescue DhanHQ::Error => e
          { success: false, error: e.message }
        end

        # Modify an existing conditional trigger
        #
        # @param args [Hash] alert_id plus full condition + orders payload
        # @return [Hash] modification result
        def modify(args)
          alert_id = args["alert_id"]
          return { error: "alert_id is required" } unless alert_id

          alert = DhanHQ::Models::AlertOrder.modify(alert_id, args.except("alert_id"))
          return { success: false, error: "Failed to modify conditional trigger" } unless alert

          { success: true }.merge(serialize_alert(alert))
        rescue DhanHQ::Error => e
          { success: false, error: e.message }
        end

        # Delete a conditional trigger
        #
        # @param args [Hash] alert_id
        # @return [Hash] deletion result
        def delete(args)
          alert_id = args["alert_id"]
          return { error: "alert_id is required" } unless alert_id

          alert = DhanHQ::Models::AlertOrder.find(alert_id)
          return { success: false, error: "Conditional trigger not found" } unless alert

          success = alert.destroy
          { success: success, alert_id: alert_id }
        rescue DhanHQ::Error => e
          { success: false, error: e.message }
        end

        # Get all conditional triggers
        #
        # @return [Array<Hash>] conditional triggers
        def all
          DhanHQ::Models::AlertOrder.all.map { |alert| serialize_alert(alert) }
        end

        # Get conditional trigger by ID
        #
        # @param args [Hash] alert_id
        # @return [Hash] conditional trigger details
        def get(args)
          alert_id = args["alert_id"]
          return { error: "alert_id is required" } unless alert_id

          alert = DhanHQ::Models::AlertOrder.find(alert_id)
          return { error: "Conditional trigger not found" } unless alert

          serialize_alert(alert)
        end

        private

        def serialize_alert(alert)
          {
            alert_id: alert.alert_id,
            exchange_segment: alert.exchange_segment,
            security_id: alert.security_id,
            condition: alert.condition,
            trigger_price: alert.trigger_price,
            order_type: alert.order_type,
            transaction_type: alert.transaction_type,
            quantity: alert.quantity,
            price: alert.price,
            status: alert.status,
            created_at: alert.created_at,
          }.compact
        end
      end
    end
  end
end
