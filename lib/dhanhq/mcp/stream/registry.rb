# frozen_string_literal: true

require "securerandom"

module Dhanhq
  module Mcp
    module Stream
      class Registry
        def initialize
          @subscriptions = {}
        end

        def add(instrument:, feed_type:)
          subscription_id = SecureRandom.uuid
          @subscriptions[subscription_id] = build_record(subscription_id, instrument, feed_type)
          subscription_id
        end

        def remove(subscription_id)
          @subscriptions.delete(subscription_id)
        end

        def all
          @subscriptions.values
        end

        private

        def build_record(subscription_id, instrument, feed_type)
          {
            id: subscription_id,
            instrument: instrument,
            feed_type: feed_type,
            created_at: Time.now,
          }
        end
      end
    end
  end
end
