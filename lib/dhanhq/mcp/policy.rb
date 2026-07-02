# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Enforces MCP tool permissions before a request reaches broker-facing code.
    #
    # The default policy is intentionally read-only: dangerous tools require both
    # explicit write enablement and live-trading opt-in flags.
    class Policy
      READ_ONLY_SCOPE = :read_only
      INTENT_SCOPE = :intent_only
      WRITE_SCOPE = :write

      attr_reader :scopes

      # @param allow_writes [Boolean] whether write-capable tools may execute
      # @param allow_live_trading [Boolean] whether live trading may execute
      # @param scopes [Array<Symbol,String>] allowed scope names
      def initialize(allow_writes: false, allow_live_trading: false, scopes: [])
        @allow_writes = allow_writes
        @allow_live_trading = allow_live_trading
        @scopes = scopes.map(&:to_sym)
      end

      # Build a policy from environment variables.
      #
      # @param env [Hash] environment-like object
      # @return [Policy]
      def self.from_env(env = ENV)
        allow_writes = truthy?(env["DHANHQ_MCP_ENABLE_WRITES"])
        allow_live_trading = truthy?(env["LIVE_TRADING"])
        scopes = env.fetch("DHANHQ_MCP_SCOPES", "read_only,intent_only").split(",").map(&:strip)
        new(allow_writes: allow_writes, allow_live_trading: allow_live_trading, scopes: scopes)
      end

      # @return [Policy] safe default for tests and embedded hosts
      def self.default
        new(scopes: [READ_ONLY_SCOPE, INTENT_SCOPE])
      end

      # Validate whether a registry entry may execute under this policy.
      #
      # @param tool [Hash] registry tool entry
      # @raise [Errors::PermissionDenied] when blocked
      # @return [true]
      # rubocop:disable Naming/PredicateMethod
      def authorize!(tool)
        scope = tool.fetch(:scope, READ_ONLY_SCOPE).to_sym
        raise Errors::PermissionDenied, "Tool #{tool[:name]} requires #{scope} scope" unless scopes.include?(scope)

        if scope == WRITE_SCOPE
          unless @allow_writes
            raise Errors::PermissionDenied, "Tool #{tool[:name]} requires DHANHQ_MCP_ENABLE_WRITES=true"
          end

          raise Errors::PermissionDenied, "Tool #{tool[:name]} requires LIVE_TRADING=true" unless @allow_live_trading
        end

        true
      end
      # rubocop:enable Naming/PredicateMethod

      def self.truthy?(value)
        %w[1 true yes on].include?(value.to_s.downcase)
      end
      private_class_method :truthy?
    end
  end
end
