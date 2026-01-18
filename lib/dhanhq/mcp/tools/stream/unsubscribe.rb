# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Stream
        class Unsubscribe < Base
          def call(args)
            subscription_id = args["subscription_id"]
            removed = registry.remove(subscription_id)
            raise Errors::InvalidArguments, "Unknown subscription" unless removed

            build_response(subscription_id)
          end

          private

          def registry
            context.meta[:stream_registry] ||= Dhanhq::Mcp::Stream::Registry.new
          end

          def build_response(subscription_id)
            {
              subscription_id: subscription_id,
              status: "unsubscribed",
            }
          end
        end
      end
    end
  end
end
