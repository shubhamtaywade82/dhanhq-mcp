# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Execute a registered trading skill by name.
      #
      # Skills are multi-step workflows that compose multiple API calls
      # into reusable trading strategies (e.g., buy_atm_call, iron_condor).
      class Skill < Base
        # Execute a skill by name with the given arguments.
        #
        # @param args [Hash] skill name and parameters
        # @return [Hash] skill execution result
        def call(args)
          skill_name = args["name"]
          params = args["params"] || {}

          validate_name!(skill_name)

          result = DhanHQ::Skills::Registry.call(skill_name, symbol_keys_to_string(params))
          { skill: skill_name, status: "completed", result: result }
        rescue KeyError, ArgumentError => e
          raise Errors::InvalidArguments, e.message
        end

        private

        def validate_name!(name)
          return if name && !name.to_s.empty?

          raise Errors::InvalidArguments, "Missing required parameter: name"
        end

        def symbol_keys_to_string(hash)
          hash.transform_keys(&:to_s)
        end
      end
    end
  end
end
