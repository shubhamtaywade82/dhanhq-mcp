# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Stream
        class Subscribe < Base
          def call(args)
            instrument = find_instrument(args)
            subscription_id = register(instrument, args["feed_type"])
            build_response(instrument, args["feed_type"], subscription_id)
          end

          private

          def find_instrument(args)
            DhanHQ::Models::Instrument.find(
              args["exchange_segment"],
              args["symbol"],
            )
          end

          def register(instrument, feed_type)
            registry.add(
              instrument: instrument_payload(instrument),
              feed_type: feed_type,
            )
          end

          def instrument_payload(instrument)
            {
              exchange_segment: instrument.exchange_segment,
              security_id: instrument.security_id,
              symbol: instrument.symbol_name,
            }
          end

          def build_response(instrument, feed_type, subscription_id)
            {
              subscription_id: subscription_id,
              instrument: instrument.symbol_name,
              feed_type: feed_type,
              status: "subscribed",
            }
          end

          def registry
            context.meta[:stream_registry] ||= Dhanhq::Mcp::Stream::Registry.new
          end
        end
      end
    end
  end
end
