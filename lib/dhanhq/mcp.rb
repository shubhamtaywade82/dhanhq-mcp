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
require_relative "mcp/policy"
require_relative "mcp/context"
require_relative "mcp/tool_spec"
require_relative "mcp/tool_registry"
require_relative "mcp/prompt_spec"
require_relative "mcp/resource_spec"
require_relative "mcp/validator"
require_relative "mcp/risk/checks/trading_permission"
require_relative "mcp/risk/checks/asm_gsm"
require_relative "mcp/risk/checks/product_support"
require_relative "mcp/risk/checks/order_type"
require_relative "mcp/risk/checks/quantity"
require_relative "mcp/risk/checks/market_hours"
require_relative "mcp/risk/checks/options"
require_relative "mcp/risk/pipeline"
require_relative "mcp/stream/registry"
require_relative "mcp/router"
require_relative "mcp/server"
require_relative "mcp/stdio_server"

require_relative "mcp/tools/base"
require_relative "mcp/tools/portfolio"
require_relative "mcp/tools/instrument"
require_relative "mcp/tools/orders"
require_relative "mcp/tools/orders_execution"
require_relative "mcp/tools/super_orders"
require_relative "mcp/tools/conditional_triggers"
require_relative "mcp/tools/positions"
require_relative "mcp/tools/margin"
require_relative "mcp/tools/traders_control"
require_relative "mcp/tools/edis"
require_relative "mcp/tools/statements"
require_relative "mcp/tools/account"
require_relative "mcp/tools/expired_options_data"
require_relative "mcp/tools/options/expiries"
require_relative "mcp/tools/options/chain"
require_relative "mcp/tools/options/selector"
require_relative "mcp/tools/options/prepare"
require_relative "mcp/tools/options/filter_chain"
require_relative "mcp/tools/options/risk_reward"
require_relative "mcp/tools/options/probability"
require_relative "mcp/tools/options/theta_analysis"
require_relative "mcp/tools/options/iv_metrics"
require_relative "mcp/tools/stream/subscribe"
require_relative "mcp/tools/stream/unsubscribe"
require_relative "mcp/tools/stream/status"
