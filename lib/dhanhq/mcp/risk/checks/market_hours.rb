# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      module Checks
        class MarketHours
          TIMEZONE_OFFSET = "+05:30"
          OPEN_HOUR = 9
          OPEN_MINUTE = 15
          CLOSE_HOUR = 15
          CLOSE_MINUTE = 30

          def self.run!(context:, **_unused)
            now = market_time(context)
            return if market_open?(now)

            raise Errors::RiskViolation, "Market is closed"
          end

          def self.market_time(context)
            provided = context.meta[:now] || context.meta["now"]
            (provided || Time.now).getlocal(TIMEZONE_OFFSET)
          end

          def self.market_open?(now)
            now.between?(market_open(now), market_close(now))
          end

          def self.market_open(now)
            Time.new(now.year, now.month, now.day, OPEN_HOUR, OPEN_MINUTE, 0, TIMEZONE_OFFSET)
          end

          def self.market_close(now)
            Time.new(now.year, now.month, now.day, CLOSE_HOUR, CLOSE_MINUTE, 0, TIMEZONE_OFFSET)
          end

          private_class_method :market_time, :market_open?, :market_open, :market_close
        end
      end
    end
  end
end
