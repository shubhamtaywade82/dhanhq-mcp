# frozen_string_literal: true

module Dhanhq
  module Mcp
    class Validator
      def self.validate!(tool_name, args)
        schema = input_schema_for!(tool_name)
        return true unless schema

        errors = build_errors(schema, args, tool_name)
        return true if errors.empty?

        raise_invalid!(tool_name, errors)
      end

      def self.input_schema_for!(tool_name)
        spec = TOOL_SPEC.find { |entry| entry[:name] == tool_name }
        return spec[:input_schema] if spec

        raise Errors::UnknownTool, tool_name
      end

      def self.build_errors(schema, args, tool_name)
        arguments = ensure_hash!(args, tool_name)
        errors = {}
        add_required_errors(schema, arguments, errors)
        add_property_errors(schema, arguments, errors)
        add_unknown_key_errors(schema, arguments, errors)
        errors
      end

      def self.ensure_hash!(args, tool_name)
        return args if args.is_a?(Hash)

        raise Errors::InvalidArguments.new(
          "Invalid arguments for #{tool_name}",
          details: { "arguments" => "expected object" },
        )
      end

      def self.add_required_errors(schema, args, errors)
        required_keys(schema).each do |key|
          errors[key] = "is required" unless args.key?(key)
        end
      end

      def self.add_property_errors(schema, args, errors)
        properties(schema).each do |key, rules|
          next unless args.key?(key)

          add_type_error(key, args[key], rules, errors)
          add_enum_error(key, args[key], rules, errors)
        end
      end

      def self.add_type_error(key, value, rules, errors)
        expected = rules[:type]
        return unless expected
        return if type_valid?(value, expected)

        errors[key] = "expected #{expected}, got #{value.class}"
      end

      def self.add_enum_error(key, value, rules, errors)
        allowed = rules[:enum]
        return unless allowed
        return if allowed.include?(value)

        errors[key] = "must be one of #{allowed.join(', ')}"
      end

      def self.add_unknown_key_errors(schema, args, errors)
        return unless reject_unknown_keys?(schema)

        unknown_keys(args, schema).each do |key|
          errors[key] = "is not permitted"
        end
      end

      def self.reject_unknown_keys?(schema)
        schema[:additionalProperties] == false
      end

      def self.unknown_keys(args, schema)
        args.keys - properties(schema).keys
      end

      def self.required_keys(schema)
        Array(schema[:required])
      end

      def self.properties(schema)
        schema[:properties] || {}
      end

      def self.raise_invalid!(tool_name, errors)
        raise Errors::InvalidArguments.new(
          "Invalid arguments for #{tool_name}",
          details: errors,
        )
      end

      def self.type_valid?(value, expected)
        case expected
        when "string" then value.is_a?(String)
        when "integer" then value.is_a?(Integer)
        when "number" then value.is_a?(Numeric)
        when "boolean" then value == true || value == false
        when Array
          expected.any? { |type| type_valid?(value, type) }
        else
          true
        end
      end

      private_class_method :input_schema_for!, :build_errors, :ensure_hash!,
                           :add_required_errors, :add_property_errors,
                           :add_type_error, :add_enum_error, :add_unknown_key_errors,
                           :reject_unknown_keys?, :unknown_keys, :required_keys,
                           :properties, :raise_invalid!, :type_valid?
    end
  end
end
