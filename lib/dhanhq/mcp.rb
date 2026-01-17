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
require_relative "mcp/validator"
require_relative "mcp/risk/checks/trading_permission"
require_relative "mcp/risk/checks/asm_gsm"
require_relative "mcp/risk/checks/product_support"
require_relative "mcp/risk/checks/order_type"
require_relative "mcp/risk/checks/quantity"
require_relative "mcp/risk/checks/market_hours"
require_relative "mcp/risk/checks/options"
require_relative "mcp/risk/pipeline"
require_relative "mcp/router"
require_relative "mcp/server"

require_relative "mcp/tools/base"
require_relative "mcp/tools/portfolio"
require_relative "mcp/tools/instrument"
require_relative "mcp/tools/orders"
require_relative "mcp/tools/options/expiries"
require_relative "mcp/tools/options/chain"
require_relative "mcp/tools/options/selector"
require_relative "mcp/tools/options/prepare"
