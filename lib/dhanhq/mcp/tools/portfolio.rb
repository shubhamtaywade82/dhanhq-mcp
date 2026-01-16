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
          DhanHQ::Models::Holding.all
        end

        # Get current positions
        #
        # @return [Array<Hash>] positions data
        def positions
          DhanHQ::Models::Position.all
        end

        # Get available funds
        #
        # @return [Hash] funds data
        def funds
          DhanHQ::Models::Funds.fetch
        end

        # Get order book
        #
        # @return [Array<Hash>] order book
        def orders
          DhanHQ::Models::Order.all
        end

        # Get trade book
        #
        # @return [Array<Hash>] trade book
        def trades
          DhanHQ::Models::Trade.today
        end
      end
    end
  end
end
