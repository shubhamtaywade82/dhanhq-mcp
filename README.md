# dhanhq-mcp

**Model Context Protocol (MCP) adapter for DhanHQ trading API**

A production-ready, infrastructure-grade Ruby gem that exposes DhanHQ trading services via the Model Context Protocol (MCP). Designed for AI agents, this gem provides safe, compliant, and Instrument-centric tools for trading operations.

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0.0-ruby.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 🎯 Purpose

`dhanhq-mcp` is a **protocol adapter** that:

- Integrates **DhanHQ** functionality through explicit **read-only**, **intent-only**, and **write-gated** MCP tools
- Enforces **compliance checks** at the abstraction layer (ASM/GSM, trading permissions)
- Provides **intent-only** order preparation by default, with broker writes disabled unless explicitly enabled
- Follows an **Instrument-centric** design for correct trading semantics
- Aligns **1:1 with the `DhanHQ` Ruby SDK**

---

## 🏗️ Architecture

### Instrument-Centric Design

Unlike typical API wrappers that expose raw client calls, `dhanhq-mcp` follows the superior **Instrument-driven** architecture:

```ruby
# ❌ Wrong (client-centric)
client.quote(security_id: "123", exchange_segment: "NSE_EQ")

# ✅ Correct (instrument-centric)
instrument = DhanHQ::Models::Instrument.find("NSE_EQ", "RELIANCE")
instrument.quote
```

**Why this matters:**
- Instruments carry trading rules (ASM/GSM, BO/CO support, margins)
- Compliance is enforced automatically
- Single source of truth for trading metadata
- Future-proof for MTF, leverage, and risk features

### Safety by Design

`dhanhq-mcp` ships as a full MCP adapter, but its default runtime policy is safe:

- **Read-only tools**: portfolio, instrument, market data, options, statements, account profile, and status-style operations.
- **Intent-only tools**: order/option preparation, margin calculations, and advanced options analysis that return previews without placing broker orders.
- **Write tools**: order placement/modification/cancellation, super orders, conditional triggers, kill-switch mutations, P&L control changes, eDIS forms, position conversion/exits, and IP mutations.

Write tools are present in `tools/list` for capability discovery, but execution is blocked unless all of the following are true:

```bash
export DHANHQ_MCP_ENABLE_WRITES=true
export LIVE_TRADING=true
export DHANHQ_MCP_SCOPES=read_only,intent_only,write
```

This means the default STDIO server can analyze markets and prepare trade intents, but it cannot place, modify, or cancel live orders.

---

## 📦 Installation

### From Source

```bash
git clone https://github.com/shubhamtaywade82/dhanhq-mcp.git
cd dhanhq-mcp
bundle install
bundle exec rake install
```

### From RubyGems (Future)

```bash
gem install dhanhq-mcp
```

---

## ⚙️ Configuration

### Setup Credentials

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your DhanHQ credentials:**
   ```bash
   # Get your credentials from: https://dhanhq.co/
   CLIENT_ID=your_client_id_here
   ACCESS_TOKEN=your_access_token_here
   ```

3. **Obtain your credentials:**
   - Login to [DhanHQ](https://dhanhq.co/)
   - Navigate to API Settings
   - Generate or copy your **Client ID** and **Access Token**

### Environment Variables

| Variable               | Required | Description                              | Default               |
| ---------------------- | -------- | ---------------------------------------- | --------------------- |
| `CLIENT_ID`            | ✅ Yes    | Your DhanHQ client ID                    | -                     |
| `ACCESS_TOKEN`         | ✅ Yes    | Your DhanHQ API access token             | -                     |
| `DHAN_LOG_LEVEL`       | ❌ No     | Logging level (DEBUG, INFO, WARN, ERROR) | `INFO`                |
| `DHAN_BASE_URL`        | ❌ No     | API base URL override                    | `https://api.dhan.co` |
| `DHAN_CONNECT_TIMEOUT` | ❌ No     | Connection timeout in seconds            | `10`                  |
| `DHAN_READ_TIMEOUT`    | ❌ No     | Read timeout in seconds                  | `30`                  |
| `DHANHQ_MCP_ENABLE_WRITES` | ❌ No | Enables write-tool execution when `true` | `false` |
| `LIVE_TRADING`         | ❌ No     | Confirms live broker-side trading when `true` | `false` |
| `DHANHQ_MCP_SCOPES`    | ❌ No     | Comma-separated MCP scopes               | `read_only,intent_only` |

**Note:** The `.env` file is automatically ignored by git to keep your credentials safe.

---

## 🚀 Usage

> **💡 Quick Start for Cursor Users**: Once configured, just ask naturally in chat! See [USAGE_IN_CURSOR.md](USAGE_IN_CURSOR.md) for examples.

### 1. STDIO Mode (Cursor, Claude Desktop, Ollama)

Best for AI assistants via STDIO protocol:

```bash
export CLIENT_ID=your_client_id
export ACCESS_TOKEN=your_access_token
bundle exec ruby bin/dhanhq-mcp-stdio
```

**MCP Protocol (JSON-RPC 2.0):**

The server implements the full MCP lifecycle. Example interaction:

**1. Initialize:**
```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {"tools": {}},
    "serverInfo": {
      "name": "dhanhq-mcp",
      "version": "0.1.0"
    }
  }
}
```

**2. Tools List:**
```json
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
```

**3. Tool Call:**
```json
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"portfolio.holdings","arguments":{}}}
```

**⚠️ Cursor-Specific Notes:**

- Cursor requires strict MCP protocol compliance
- Use `bundle exec` to ensure proper gem loading
- `.env` files are **not** auto-loaded by Cursor - set environment variables explicitly
- All responses must include `jsonrpc`, `id`, and `result`/`error` fields
- No output to STDOUT except JSON-RPC messages (logs go to STDERR)

### 2. Rails Integration

Use in your Rails app with dependency injection:

```ruby
# config/initializers/dhanhq_mcp.rb
require 'dhanhq-mcp'

client = DhanHQ::Client.new(access_token: ENV['DHAN_ACCESS_TOKEN'])
$mcp_context = Dhanhq::Mcp::Context.new(client: client)
```

**Controller usage:**
```ruby
class TradingController < ApplicationController
  def prepare_order
    result = Dhanhq::Mcp::Router.call(
      "orders.prepare",
      {
        "exchange_segment" => "NSE_EQ",
        "symbol" => "RELIANCE",
        "transaction_type" => "BUY",
        "product_type" => "INTRADAY",
        "order_type" => "MARKET",
        "quantity" => 10
      },
      $mcp_context
    )

    render json: result
  end
end
```

### 3. HTTP Server Mode

Run as Rack application:

```ruby
# config.ru
require 'dhanhq-mcp'

client = DhanHQ::Client.new(access_token: ENV['DHAN_ACCESS_TOKEN'])
app = Dhanhq::Mcp::Server.new(
  context_provider: ->(req) {
    Dhanhq::Mcp::Context.new(client: client)
  }
)

run app
```

```bash
rackup -p 3000
```

---

## 🔧 Tool Inventory (68 tools)

### Portfolio Tools (5) - Read-Only

| Tool                  | Description            |
| --------------------- | ---------------------- |
| `portfolio.holdings`  | Get current holdings   |
| `portfolio.positions` | Get current positions  |
| `portfolio.funds`     | Get available funds    |
| `portfolio.orders`    | Get order book history |
| `portfolio.trades`    | Get trade book history |

**Example:**
```ruby
Dhanhq::Mcp::Router.call("portfolio.positions", {}, context)
# => [{symbol: "RELIANCE", quantity: 10, avg_price: 2500.0, ...}, ...]
```

### Instrument Tools (7) - Read-Only

| Tool                  | Description                         |
| --------------------- | ----------------------------------- |
| `instrument.find`     | Discover & validate instrument      |
| `instrument.info`     | Trading permissions & risk metadata |
| `instrument.ltp`      | Last traded price                   |
| `instrument.quote`    | Full market quote                   |
| `instrument.ohlc`     | OHLC snapshot                       |
| `instrument.daily`    | Daily historical candles            |
| `instrument.intraday` | Intraday candles                    |

**Example:**
```ruby
Dhanhq::Mcp::Router.call(
  "instrument.quote",
  {"exchange_segment" => "NSE_EQ", "symbol" => "RELIANCE"},
  context
)
# => {ltp: 2500.0, bid: 2499.5, ask: 2500.5, volume: 1000000, ...}
```

### Options Analysis Tools (8) - Read-Only

| Tool                  | Description                                    |
| --------------------- | ---------------------------------------------- |
| `option.expiries`     | Available option expiries                     |
| `option.chain`        | Option chain data                             |
| `option.select`       | Rule-based strike selection                   |
| `option.filter_chain` | Advanced chain filtering with OI/volume/IV    |
| `option.risk_reward`  | Calculate risk-reward metrics                 |
| `option.probability`  | Calculate probability metrics                  |
| `option.theta_analysis` | Analyze theta decay over time               |
| `option.iv_metrics`   | Calculate IV percentile and rank              |

**Examples:**
```ruby
# 1. Get expiries
Dhanhq::Mcp::Router.call(
  "option.expiries",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY"},
  context
)

# 2. Get chain
Dhanhq::Mcp::Router.call(
  "option.chain",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY", "expiry" => "2026-01-30"},
  context
)

# 3. Advanced filter
Dhanhq::Mcp::Router.call(
  "option.filter_chain",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "expiry" => "2026-01-30",
    "spot_price" => 23100,
    "filters" => {
      "min_oi" => 100000,
      "min_volume" => 50000,
      "min_iv" => 10,
      "max_iv" => 50
    },
    "sort_by" => "volume",
    "limit" => 10
  },
  context
)

# 4. Risk-reward
Dhanhq::Mcp::Router.call(
  "option.risk_reward",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "strike" => 23200,
    "option_type" => "CE",
    "premium" => 150,
    "quantity" => 50,
    "spot_price" => 23100
  },
  context
)

# 5. Probability
Dhanhq::Mcp::Router.call(
  "option.probability",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "strike" => 23200,
    "option_type" => "CE",
    "premium" => 150,
    "expiry" => "2026-01-30",
    "spot_price" => 23100,
    "iv" => 18.0
  },
  context
)

# 6. Theta analysis
Dhanhq::Mcp::Router.call(
  "option.theta_analysis",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "strike" => 23200,
    "option_type" => "CE",
    "premium" => 150,
    "expiry" => "2026-01-30",
    "spot_price" => 23100,
    "iv" => 18.0
  },
  context
)

# 7. IV metrics
Dhanhq::Mcp::Router.call(
  "option.iv_metrics",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "expiry" => "2026-01-30",
    "spot_price" => 23100
  },
  context
)
```

### Options Tools (1) - Intent-Only

| Tool         | Description                          |
| ------------ | ------------------------------------ |
| `option.prepare` | Prepare OPTIONS BUY intent         |

**Example:**
```ruby
Dhanhq::Mcp::Router.call(
  "option.prepare",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "security_id" => "52175",
    "option_type" => "CE",
    "strike" => 23200,
    "expiry" => "2026-01-30",
    "quantity" => 50,
    "stop_loss" => 100,
    "target" => 200
  },
  context
)
# => {trade_type: "OPTIONS_BUY", instrument: "NIFTY 23200 CE", ...}
```

### Orders Tools (10) - Execution / Write

| Tool                  | Description                       |
| --------------------- | --------------------------------- |
| `orders.place`        | Place a new order                 |
| `orders.modify`       | Modify a pending order            |
| `orders.cancel`       | Cancel a pending order            |
| `orders.get`          | Get order details by order ID     |
| `orders.get_by_correlation` | Get order by correlation ID |
| `orders.get_trades`   | Get trades for an order           |
| `orders.history`      | Get trade history for date range  |
| `orders.slice`        | Slice order into multiple legs    |

### Orders Tools (1) - Intent-Only

| Tool             | Description                                    |
| ---------------- | ---------------------------------------------- |
| `orders.prepare` | Prepare EQUITY/FUTURES trade intent            |

**Example:**
```ruby
Dhanhq::Mcp::Router.call(
  "orders.prepare",
  {
    "exchange_segment" => "NSE_EQ",
    "symbol" => "RELIANCE",
    "transaction_type" => "BUY",
    "product_type" => "INTRADAY",
    "order_type" => "MARKET",
    "quantity" => 10
  },
  context
)
# => {trade_type: "EQUITY_FUTURES", instrument: "RELIANCE (NSE_EQ)", ...}
```

### Super Orders (5)

| Tool                  | Description                       | Type   |
| --------------------- | --------------------------------- | ------ |
| `super_orders.place`  | Place super/bracket order         | Write  |
| `super_orders.modify` | Modify super order leg            | Write  |
| `super_orders.cancel_leg` | Cancel specific leg            | Write  |
| `super_orders.all`    | Get all super orders for the day  | Read-Only |
| `super_orders.get`    | Get super order by ID             | Read-Only |

### Conditional Triggers (5)

| Tool                           | Description                        | Type   |
| ------------------------------ | ---------------------------------- | ------ |
| `conditional_triggers.place`   | Create conditional trigger         | Write  |
| `conditional_triggers.modify`  | Modify conditional trigger         | Write  |
| `conditional_triggers.delete`  | Delete conditional trigger         | Write  |
| `conditional_triggers.all`     | Get all conditional triggers       | Read-Only |
| `conditional_triggers.get`     | Get trigger by ID                  | Read-Only |

### Positions (3)

| Tool                  | Description                        | Type   |
| --------------------- | ---------------------------------- | ------ |
| `positions.active`    | Get only active/open positions     | Read-Only |
| `positions.convert`   | Convert between product types      | Write  |
| `positions.exit_all`  | Exit all open positions            | Write  |

### Margin (2) - Intent-Only

| Tool                     | Description                        |
| ------------------------ | ---------------------------------- |
| `margin.calculate`       | Calculate margin for single order  |
| `margin.calculate_multi` | Calculate margin for multiple orders |

### Trader's Control (6)

| Tool                           | Description                        | Type   |
| ------------------------------ | ---------------------------------- | ------ |
| `traders_control.kill_switch_status` | Get kill switch status       | Read-Only |
| `traders_control.activate_kill_switch` | Activate kill switch        | Write  |
| `traders_control.deactivate_kill_switch` | Deactivate kill switch     | Write  |
| `traders_control.configure_pnl_exit` | Configure P&L auto-exit       | Write  |
| `traders_control.get_pnl_exit`       | Get P&L exit config           | Read-Only |
| `traders_control.stop_pnl_exit`      | Stop P&L auto-exit            | Write  |

### eDIS (4)

| Tool                  | Description                        | Type   |
| --------------------- | ---------------------------------- | ------ |
| `edis.tpin`           | Generate T-PIN for EDIS auth       | Read-Only |
| `edis.form`           | Generate eDIS form for single stock| Write  |
| `edis.bulk_form`      | Generate bulk eDIS form            | Write  |
| `edis.inquire`        | Check EDIS status                  | Read-Only |

### Statements (2)

| Tool                      | Description                        |
| ------------------------- | ---------------------------------- |
| `statements.ledger`       | Get ledger report for date range  |
| `statements.trade_history`| Get trade history for date range  |

### Account (4)

| Tool                  | Description                        | Type   |
| --------------------- | ---------------------------------- | ------ |
| `account.get_ip`      | Get configured static IPs          | Read-Only |
| `account.set_ip`      | Set primary/secondary IP           | Write  |
| `account.modify_ip`   | Modify primary/secondary IP        | Write  |
| `account.profile`     | Get user profile information       | Read-Only |

### Expired Options Data (1)

| Tool                          | Description                                    |
| ----------------------------- | ---------------------------------------------- |
| `expired_options_data.get`    | Get historical rolling options data with OHLC |

### Skills (2)

| Tool              | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `skill.list`      | List all registered trading skills                      |
| `skill.execute`    | Execute a trading skill by name                        |

### Streaming (3)

| Tool                  | Description                        |
| --------------------- | ---------------------------------- |
| `stream.subscribe`    | Subscribe to live market data      |
| `stream.unsubscribe`  | Unsubscribe from live market data  |
| `stream.status`       | List active subscriptions          |

---

## 🔄 Complete Trading Workflows

### Options Trading Workflow

```ruby
# 1. Check available funds
funds = Dhanhq::Mcp::Router.call("portfolio.funds", {}, context)
puts "Available margin: #{funds[:available_balance]}"

# 2. Discover index instrument
inst = Dhanhq::Mcp::Router.call(
  "instrument.find",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY"},
  context
)

# 3. Check trading permissions
info = Dhanhq::Mcp::Router.call(
  "instrument.info",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY"},
  context
)
raise "Trading not allowed" unless info[:trading_allowed]

# 4. Get current spot price
ltp = Dhanhq::Mcp::Router.call(
  "instrument.ltp",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY"},
  context
)
spot = ltp[:ltp]

# 5. Get option expiries
expiries = Dhanhq::Mcp::Router.call(
  "option.expiries",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY"},
  context
)
expiry = expiries.first

# 6. Get option chain
chain = Dhanhq::Mcp::Router.call(
  "option.chain",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY", "expiry" => expiry},
  context
)

# 7. Rule-based strike selection
strikes = Dhanhq::Mcp::Router.call(
  "option.select",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "expiry" => expiry,
    "direction" => "BULLISH",
    "spot_price" => spot,
    "max_distance_pct" => 1.0,
    "min_premium" => 50,
    "max_premium" => 300
  },
  context
)
selected = strikes.first

# 8. Prepare trade intent
intent = Dhanhq::Mcp::Router.call(
  "option.prepare",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "security_id" => selected[:security_id],
    "option_type" => selected[:option_type],
    "strike" => selected[:strike],
    "expiry" => expiry,
    "quantity" => 50,
    "stop_loss" => 100,
    "target" => 200
  },
  context
)

# 9. ⚠️ HUMAN CONFIRMATION REQUIRED ⚠️
puts "Trade Intent: #{intent}"
puts "Awaiting human confirmation..."

# 10. (In Rails/external system) Execute after confirmation
# client.place_option_order(...) ← NOT exposed via MCP
```

### Equity Trading Workflow

```ruby
# 1. Check current positions
positions = Dhanhq::Mcp::Router.call("portfolio.positions", {}, context)

# 2. Discover equity instrument
inst = Dhanhq::Mcp::Router.call(
  "instrument.find",
  {"exchange_segment" => "NSE_EQ", "symbol" => "RELIANCE"},
  context
)

# 3. Analyze price history
daily = Dhanhq::Mcp::Router.call(
  "instrument.daily",
  {
    "exchange_segment" => "NSE_EQ",
    "symbol" => "RELIANCE",
    "from" => "2026-01-01",
    "to" => "2026-01-17"
  },
  context
)

# 4. Get current quote
quote = Dhanhq::Mcp::Router.call(
  "instrument.quote",
  {"exchange_segment" => "NSE_EQ", "symbol" => "RELIANCE"},
  context
)

# 5. Prepare order intent
intent = Dhanhq::Mcp::Router.call(
  "orders.prepare",
  {
    "exchange_segment" => "NSE_EQ",
    "symbol" => "RELIANCE",
    "transaction_type" => "BUY",
    "product_type" => "INTRADAY",
    "order_type" => "LIMIT",
    "quantity" => 10,
    "price" => quote[:ltp] * 0.99  # 1% below LTP
  },
  context
)

# 6. ⚠️ HUMAN CONFIRMATION REQUIRED ⚠️
puts "Trade Intent: #{intent}"
puts "Awaiting human confirmation..."

# 7. (In Rails/external system) Execute after confirmation
# client.place_order(...) ← NOT exposed via MCP
```

---

## 🛡️ Compliance & Safety Features

### Automatic Compliance Checks

All order/option preparation tools enforce:

- ✅ **Trading Permissions** (`buy_sell_indicator == "A"`)
- ✅ **ASM/GSM Restrictions** (raises error if restricted)
- ✅ **Instrument Type Validation** (options only for INDEX instruments)
- ✅ **Quantity Validation** (quantity > 0)
- ✅ **Risk-Reward Validation** (target > stop_loss)
- ✅ **Order Type Validation** (price required for LIMIT, trigger_price for STOP_LOSS)
- ✅ **Product Support** (BO/CO flags checked against instrument capabilities)

### No Auto-Execution

- ❌ `place_order` - NOT exposed
- ❌ `modify_order` - NOT exposed
- ❌ `cancel_order` - NOT exposed
- ✅ `orders.prepare` - Returns intent only
- ✅ `option.prepare` - Returns intent only

**Execution flow:**
```
MCP (prepare) → Intent → Rails/Human → Confirmation → DhanHQ (execute)
```

---

## 🧪 Testing

### Run Full Test Suite

```bash
bundle exec rake
```

### Manual Testing with STDIO

```bash
# Test portfolio tools
bin/test-portfolio

# Test instrument tools
bin/test-instrument

# Test options tools
bin/test-options

# Test order preparation
bin/test-orders
```

### Test Individual Tools

```bash
echo '{"method":"tools/call","params":{"name":"portfolio.funds","arguments":{}}}' | bin/dhanhq-mcp-stdio
```

---

## 📊 Code Quality

- ✅ **RuboCop**: 0 offenses, Clean Ruby principles enforced
- ✅ **RSpec**: Test suite with coverage tracking
- ✅ **YARD**: 100% documentation coverage
- ✅ **Method Length**: All methods < 10 lines
- ✅ **Complexity**: Low cyclomatic complexity
- ✅ **Naming**: Intention-revealing names throughout

### Run Quality Checks

```bash
# Linting
bundle exec rubocop

# Documentation
bundle exec yard doc
bundle exec yard stats

# Coverage
bundle exec rake spec
```

---

## 🔧 Development

### Project Structure

```
lib/dhanhq/mcp/
├── server.rb             # Rack-based MCP HTTP server
├── stdio_server.rb       # STDIO MCP server (Claude Desktop / CLI)
├── router.rb             # Routes MCP calls to ToolRegistry
├── tool_registry.rb      # Single source of truth for tool metadata + dispatch
├── tool_spec.rb          # 67 MCP tool specifications (contract)
├── prompt_spec.rb        # Prompt template definitions
├── resource_spec.rb      # Resource endpoint definitions
├── context.rb            # Dependency injection container
├── errors.rb             # Custom error classes
├── policy.rb             # Read/intent/write permission gates
├── validator.rb          # Input validation
├── version.rb            # Gem version
├── stream/
│   └── registry.rb       # Streaming registry helpers
└── tools/
    ├── base.rb           # Base class for all tools
    ├── portfolio.rb      # Portfolio read-only tools
    ├── instrument.rb     # Instrument discovery & market data
    ├── orders.rb         # Order preparation (intent-only)
    ├── orders_execution.rb # Live order execution tools
    ├── super_orders.rb   # Super/bracket order tools
    ├── conditional_triggers.rb # Conditional trigger tools
    ├── positions.rb      # Position management
    ├── margin.rb         # Margin calculator tools
    ├── traders_control.rb # Kill switch / P&L exit tools
    ├── edis.rb           # eDIS form tools
    ├── statements.rb     # Ledger & trade history tools
    ├── account.rb        # IP / profile tools
    ├── expired_options_data.rb # Historical expired options data
    ├── skill.rb          # Skill execution tools
    ├── options/
    │   ├── expiries.rb   # Option expiry list
    │   ├── chain.rb      # Option chain fetcher
    │   ├── selector.rb   # Rule-based strike selector
    │   ├── prepare.rb    # Options trade preparation
    │   ├── filter_chain.rb # Advanced chain filtering
    │   ├── risk_reward.rb # Risk-reward calculations
    │   ├── probability.rb # Probability metrics
    │   ├── theta_analysis.rb # Theta decay analysis
    │   └── iv_metrics.rb  # IV percentile / rank
    └── stream/
        ├── subscribe.rb  # Subscribe to market data
        ├── unsubscribe.rb # Unsubscribe from market data
        └── status.rb     # Subscription status
```

### Adding New Tools

1. Add tool specification to `tool_spec.rb`
2. Create tool class inheriting from `Tools::Base`
3. Add handler to `ToolRegistry::HANDLERS`
4. Add scope membership in `ToolRegistry::WRITE_TOOLS` / `INTENT_TOOLS` if applicable
5. Require the tool in `lib/dhanhq/mcp.rb`

**Example:**
```ruby
# 1. tool_spec.rb
{
  name: "portfolio.summary",
  description: "Get portfolio summary",
  input_schema: { type: "object", properties: {} }
}

# 2. tools/portfolio_summary.rb
module Dhanhq
  module Mcp
    module Tools
      class PortfolioSummary < Base
        def call(_args)
          client = context.client
          {
            total_value: client.funds[:available_balance],
            holdings_count: client.holdings.count,
            positions_count: client.positions.count
          }
        end
      end
    end
  end
end

# 3. tool_registry.rb
{
  "portfolio.summary" => ->(context, _args) {
    Tools::PortfolioSummary.new(context).call(_args)
  }
}

# 4. lib/dhanhq/mcp.rb
require_relative "mcp/tools/portfolio_summary"
```

---

## 🎯 Design Principles

### 1. Instrument-Centric
Every trading operation starts with `Instrument.find` to ensure compliance and proper abstraction.

### 2. Intent-Only Orders
MCP tools prepare trade intents; execution happens outside MCP with human confirmation.

### 3. Clean Ruby
- Methods do one thing
- Names reveal intent
- No premature optimization
- Refactor continuously

### 4. Dependency Injection
All tools receive a `Context` object with the `DhanHQ` client instance, enabling testability.

### 5. Protocol Adapter
`dhanhq-mcp` is a thin, safe adapter—not a reimplementation. It exposes a bounded subset of `DhanHQ`.

---

## 🚀 Production Deployment

### Environment Variables

```bash
DHAN_ACCESS_TOKEN=your_token_here
```

### Docker (Optional)

```dockerfile
FROM ruby:3.3.4-alpine

RUN apk add --no-cache build-base git

WORKDIR /app
COPY Gemfile* ./
RUN bundle install

COPY . .
CMD ["bin/dhanhq-mcp-stdio"]
```

### Systemd Service (STDIO)

```ini
[Unit]
Description=DhanHQ MCP STDIO Server
After=network.target

[Service]
Type=simple
User=trading
WorkingDirectory=/opt/dhanhq-mcp
Environment="DHAN_ACCESS_TOKEN=your_token"
ExecStart=/usr/local/bin/dhanhq-mcp-stdio
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## 📚 Resources

- **DhanHQ Ruby SDK**: [https://github.com/shubhamtaywade82/DhanHQ](https://github.com/shubhamtaywade82/DhanHQ)
- **Model Context Protocol**: [MCP Specification](https://modelcontextprotocol.io/)
- **DhanHQ API Docs**: [https://dhanhq.co/docs/v2/](https://dhanhq.co/docs/v2/)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Code Quality Requirements:**
- RuboCop passes with 0 offenses
- All tests pass
- Coverage maintained above 90%
- YARD documentation updated

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

**This gem is for algorithmic trading via AI agents. Real money is at risk.**

- Always test in paper trading first
- Implement proper risk management
- Review all trade intents before execution
- This software is provided AS-IS with no warranty
- Authors not liable for trading losses

---

## 🙏 Acknowledgments

- Built on top of [`dhanhq-client`](https://github.com/shubhamtaywade82/dhanhq-client)
- Follows Clean Ruby principles by [Uncle Bob Martin](https://www.oreilly.com/library/view/clean-code-a/9780136083238/)
- Adheres to [Model Context Protocol](https://modelcontextprotocol.io/) specification

---

**Made with ❤️ for infrastructure-grade trading systems**
