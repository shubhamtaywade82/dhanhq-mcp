# frozen_string_literal: true

# Stub for DhanHQ gem in tests
module DhanHQ
  module Models
    class Instrument
      def self.find(_exchange_segment, _symbol)
        raise NotImplementedError, "Stub this method in tests"
      end
    end

    class Holding
      def self.all
        raise NotImplementedError, "Stub this method in tests"
      end
    end

    class Position
      def self.all
        raise NotImplementedError, "Stub this method in tests"
      end
    end

    class Funds
      def self.fetch
        raise NotImplementedError, "Stub this method in tests"
      end
    end

    class Order
      def self.all
        raise NotImplementedError, "Stub this method in tests"
      end
    end

    class Trade
      def self.today
        raise NotImplementedError, "Stub this method in tests"
      end
    end
  end
end
