# frozen_string_literal: true

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

require_relative "mcp/version"
require_relative "mcp/errors"
require_relative "mcp/context"
require_relative "mcp/tool_spec"
require_relative "mcp/router"
require_relative "mcp/server"

require_relative "mcp/tools/base"
require_relative "mcp/tools/instrument"
