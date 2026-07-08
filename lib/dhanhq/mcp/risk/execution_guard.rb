# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Risk
      # Server-side guardrails that run before any order execution tool touches
      # the broker. Mirrors the documented DhanHQ agent-skill safety mechanisms:
      #
      # 1. LIMIT-by-default — omitted order_type resolves to LIMIT; LIMIT and
      #    STOP_LOSS orders must carry a price, stop-loss variants a trigger price.
      # 2. Lot-size validation — F&O quantities must be positive multiples of the
      #    instrument's lot size (when the instrument master is available).
      # 3. Instrument-level checks — trading permission, ASM/GSM restriction and
      #    BO/CO product support via the client's risk checks.
      #
      # Market hours are enforced for non-AMO orders. Optional hard caps can be
      # configured with DHANHQ_MCP_MAX_QUANTITY and DHANHQ_MCP_MAX_NOTIONAL.
      #
      # All violations raise DhanHQ::RiskViolation, which the tool registry
      # translates into Errors::RiskViolation for the MCP client.
      class ExecutionGuard
        FNO_SEGMENTS = %w[NSE_FNO BSE_FNO NSE_COMM MCX_COMM].freeze
        ORDER_TYPES = %w[LIMIT MARKET STOP_LOSS STOP_LOSS_MARKET].freeze
        PRICED_TYPES = %w[LIMIT STOP_LOSS].freeze
        TRIGGERED_TYPES = %w[STOP_LOSS STOP_LOSS_MARKET].freeze

        class << self
          # Validate args for a new order placement (orders.place, orders.slice,
          # super_orders.place). Returns a normalized copy of args with the
          # LIMIT default applied.
          #
          # @param args [Hash] tool arguments (string keys)
          # @param now [Time] reference time for the market-hours check
          # @return [Hash] normalized args
          # @raise [DhanHQ::RiskViolation] on the first failed check
          def for_placement!(args, now: Time.now)
            normalized = apply_limit_default(args)
            validate_order_type!(normalized)
            validate_prices!(normalized)
            validate_quantity!(normalized)
            validate_market_hours!(normalized, now)
            enforce_env_caps!(normalized)
            validate_instrument!(normalized)
            normalized
          end

          # Validate args for an order modification. Only the fields present are
          # checked — a modification may change just price or quantity.
          #
          # @param args [Hash] tool arguments (string keys)
          # @return [Hash] args, unchanged
          # @raise [DhanHQ::RiskViolation] on the first failed check
          def for_modification!(args)
            if args["order_type"]
              validate_order_type!(args)
              validate_prices!(args)
            end
            validate_quantity!(args) if args.key?("quantity")
            enforce_env_caps!(args) if args.key?("quantity")
            args
          end

          private

          def apply_limit_default(args)
            normalized = args.dup
            order_type = normalized["order_type"]
            normalized["order_type"] = "LIMIT" if order_type.nil? || order_type.to_s.empty?
            normalized
          end

          def validate_order_type!(args)
            order_type = args["order_type"]
            return if ORDER_TYPES.include?(order_type)

            raise DhanHQ::RiskViolation, "Invalid order type #{order_type.inspect}"
          end

          def validate_prices!(args)
            order_type = args["order_type"]
            if PRICED_TYPES.include?(order_type) && !positive_number?(args["price"])
              raise DhanHQ::RiskViolation, "#{order_type} orders require a positive price"
            end
            return unless TRIGGERED_TYPES.include?(order_type) && !positive_number?(args["trigger_price"])

            raise DhanHQ::RiskViolation, "#{order_type} orders require a positive trigger_price"
          end

          def validate_quantity!(args)
            quantity = args["quantity"].to_i
            return if quantity.positive?

            raise DhanHQ::RiskViolation, "Quantity must be > 0"
          end

          def validate_market_hours!(args, now)
            return if truthy?(args["after_market_order"])

            DhanHQ::Risk::Checks::MarketHours.run!(now: now)
          end

          def enforce_env_caps!(args)
            quantity = args["quantity"].to_i
            max_quantity = ENV.fetch("DHANHQ_MCP_MAX_QUANTITY", nil)
            if max_quantity && quantity > max_quantity.to_i
              raise DhanHQ::RiskViolation, "Quantity exceeds DHANHQ_MCP_MAX_QUANTITY (#{max_quantity})"
            end

            max_notional = ENV.fetch("DHANHQ_MCP_MAX_NOTIONAL", nil)
            return unless max_notional && args["price"]

            notional = quantity * args["price"].to_f
            return if notional <= max_notional.to_f

            raise DhanHQ::RiskViolation, "Notional exceeds DHANHQ_MCP_MAX_NOTIONAL (#{max_notional})"
          end

          # Instrument-level checks are best-effort: when the instrument master
          # is unavailable (download failure, unknown security id) the
          # args-level guardrails above still apply, but per-instrument
          # restrictions cannot be evaluated.
          def validate_instrument!(args)
            instrument = resolve_instrument(args)
            return unless instrument

            DhanHQ::Risk::Checks::TradingPermission.run!(instrument: instrument)
            DhanHQ::Risk::Checks::AsmGsm.run!(instrument: instrument)
            DhanHQ::Risk::Checks::ProductSupport.run!(args: args, instrument: instrument)
            validate_lot_size!(args, instrument)
          end

          def validate_lot_size!(args, instrument)
            return unless FNO_SEGMENTS.include?(args["exchange_segment"])

            lot_size = instrument.lot_size.to_i
            return if lot_size <= 1

            quantity = args["quantity"].to_i
            return if (quantity % lot_size).zero?

            raise DhanHQ::RiskViolation,
                  "Quantity #{quantity} is not a multiple of lot size #{lot_size}"
          end

          def resolve_instrument(args)
            security_id = args["security_id"].to_s
            segment = args["exchange_segment"].to_s
            return nil if security_id.empty? || segment.empty?

            DhanHQ::Models::Instrument.by_segment(segment)
                                      .find { |instrument| instrument.security_id.to_s == security_id }
          rescue DhanHQ::RiskViolation
            raise
          rescue StandardError
            nil
          end

          def positive_number?(value)
            value.respond_to?(:to_f) && value.to_f.positive?
          end

          def truthy?(value)
            [true, "true", 1, "1"].include?(value)
          end
        end
      end
    end
  end
end
