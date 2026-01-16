# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Portfolio read-only tools
      class Portfolio < Base
        # Get current holdings
        #
        # @return [Array<Hash>] holdings data
        def holdings
          serialize_collection(DhanHQ::Models::Holding.all)
        end

        # Get current positions
        #
        # @return [Array<Hash>] positions data
        def positions
          serialize_collection(DhanHQ::Models::Position.all)
        end

        # Get available funds
        #
        # @return [Hash] funds data
        def funds
          serialize_object(DhanHQ::Models::Funds.fetch)
        end

        # Get order book
        #
        # @return [Array<Hash>] order book
        def orders
          serialize_collection(DhanHQ::Models::Order.all)
        end

        # Get trade book
        #
        # @return [Array<Hash>] trade book
        def trades
          serialize_collection(DhanHQ::Models::Trade.today)
        end

        private

        def serialize_collection(collection)
          collection.map { |item| serialize_object(item) }
        end

        def serialize_object(obj)
          return obj if obj.is_a?(Hash)
          return obj.to_h if obj.respond_to?(:to_h)
          return obj.attributes if obj.respond_to?(:attributes)

          obj
        end
      end
    end
  end
end
