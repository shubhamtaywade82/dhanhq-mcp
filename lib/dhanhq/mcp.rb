# frozen_string_literal: true

require_relative "mcp/version"

# Dhanhq namespace module
module Dhanhq
  # MCP (Model Context Protocol) implementation for DhanHQ
  #
  # This gem provides a Ruby implementation for interacting with DhanHQ
  # services using the Model Context Protocol.
  #
  # @author Shubham Taywade
  module Mcp
    # Base error class for all Dhanhq::Mcp errors
    class Error < StandardError; end
  end
end
