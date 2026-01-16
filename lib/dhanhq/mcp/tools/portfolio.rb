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
          context.client.holdings
        end

        # Get current positions
        #
        # @return [Array<Hash>] positions data
        def positions
          context.client.positions
        end

        # Get available funds
        #
        # @return [Hash] funds data
        def funds
          context.client.funds
        end

        # Get order book
        #
        # @return [Array<Hash>] order book
        def orders
          context.client.order_book
        end

        # Get trade book
        #
        # @return [Array<Hash>] trade book
        def trades
          context.client.trade_book
        end
      end
    end
  end
end
