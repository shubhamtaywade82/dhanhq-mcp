# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      module Stream
        class Status < Base
          def call(_args = {})
            registry.all
          end

          private

          def registry
            context.meta[:stream_registry] ||= Dhanhq::Mcp::Stream::Registry.new
          end
        end
      end
    end
  end
end
