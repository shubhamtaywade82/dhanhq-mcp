# dhanhq-mcp

**Model Context Protocol (MCP) adapter for DhanHQ trading API**

A production-ready, infrastructure-grade Ruby gem that exposes DhanHQ trading services via the Model Context Protocol (MCP). Designed for AI agents, this gem provides safe, compliant, and Instrument-centric tools for trading operations.

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0.0-ruby.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 🎯 Purpose

`dhanhq-mcp` is a **protocol adapter** that:

- Exposes a **safe subset** of `dhanhq-client` functionality to AI agents
- Enforces **compliance checks** at the abstraction layer (ASM/GSM, trading permissions)
- Provides **intent-only** order preparation (no auto-execution)
- Follows an **Instrument-centric** design for correct trading semantics
- Aligns **1:1 with `dhanhq-client`** architecture

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

- **Read-Only Tools (12)**: Market data, portfolio, instrument discovery
- **Intent-Only Tools (2)**: Order preparation with no execution
- **Zero Auto-Execution**: No `place_order`, `modify_order`, or `cancel_order` exposed

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

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `CLIENT_ID` | ✅ Yes | Your DhanHQ client ID | - |
| `ACCESS_TOKEN` | ✅ Yes | Your DhanHQ API access token | - |
| `DHAN_LOG_LEVEL` | ❌ No | Logging level (DEBUG, INFO, WARN, ERROR) | `INFO` |
| `DHAN_BASE_URL` | ❌ No | API base URL override | `https://api.dhan.co` |
| `DHAN_CONNECT_TIMEOUT` | ❌ No | Connection timeout in seconds | `10` |
| `DHAN_READ_TIMEOUT` | ❌ No | Read timeout in seconds | `30` |

**Note:** The `.env` file is automatically ignored by git to keep your credentials safe.

---

## 🚀 Usage

### 1. STDIO Mode (Claude Desktop, Ollama)

Best for AI assistants via STDIO protocol:

```bash
export DHAN_ACCESS_TOKEN=your_token
dhanhq-mcp-stdio
```

**Input:**
```json
{"method":"tools/list"}
```

**Output:**
```json
{"result":[{"name":"portfolio.holdings","description":"Get current holdings"}, ...]}
```

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

## 🔧 Complete Tool Inventory (17 Tools)

### Portfolio Tools (5) - Read-Only

| Tool | Description | Arguments |
|------|-------------|-----------|
| `portfolio.holdings` | Get current holdings | None |
| `portfolio.positions` | Get current positions | None |
| `portfolio.funds` | Get available funds | None |
| `portfolio.orders` | Get order book history | None |
| `portfolio.trades` | Get trade book history | None |

**Example:**
```ruby
Dhanhq::Mcp::Router.call("portfolio.positions", {}, context)
# => [{symbol: "RELIANCE", quantity: 10, avg_price: 2500.0, ...}, ...]
```

### Instrument Tools (7) - Read-Only

| Tool | Description | Arguments |
|------|-------------|-----------|
| `instrument.find` | Discover & validate instrument | `exchange_segment`, `symbol` |
| `instrument.info` | Trading permissions & risk metadata | `exchange_segment`, `symbol` |
| `instrument.ltp` | Last traded price | `exchange_segment`, `symbol` |
| `instrument.quote` | Full market quote | `exchange_segment`, `symbol` |
| `instrument.ohlc` | OHLC snapshot | `exchange_segment`, `symbol` |
| `instrument.daily` | Daily historical candles | `exchange_segment`, `symbol`, `from`, `to` |
| `instrument.intraday` | Intraday candles | `exchange_segment`, `symbol`, `from`, `to`, `interval` |

**Example:**
```ruby
Dhanhq::Mcp::Router.call(
  "instrument.quote",
  {"exchange_segment" => "NSE_EQ", "symbol" => "RELIANCE"},
  context
)
# => {ltp: 2500.0, bid: 2499.5, ask: 2500.5, volume: 1000000, ...}
```

### Options Tools (4)

| Tool | Description | Arguments | Type |
|------|-------------|-----------|------|
| `option.expiries` | Available option expiries | `exchange_segment`, `symbol` | Read-Only |
| `option.chain` | Option chain data | `exchange_segment`, `symbol`, `expiry` | Read-Only |
| `option.select` | Rule-based strike selection | `exchange_segment`, `symbol`, `expiry`, `direction`, `spot_price`, etc. | Read-Only |
| `option.prepare` | Prepare OPTIONS BUY intent | `exchange_segment`, `symbol`, `security_id`, `option_type`, `strike`, `expiry`, `quantity`, `stop_loss`, `target` | Intent-Only |

**Example:**
```ruby
# 1. Get expiries
Dhanhq::Mcp::Router.call(
  "option.expiries",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY"},
  context
)
# => ["2026-01-30", "2026-02-06", ...]

# 2. Get chain
Dhanhq::Mcp::Router.call(
  "option.chain",
  {"exchange_segment" => "IDX_I", "symbol" => "NIFTY", "expiry" => "2026-01-30"},
  context
)
# => [{strike: 23000, option_type: "CE", ltp: 150, ...}, ...]

# 3. Select strike
Dhanhq::Mcp::Router.call(
  "option.select",
  {
    "exchange_segment" => "IDX_I",
    "symbol" => "NIFTY",
    "expiry" => "2026-01-30",
    "direction" => "BULLISH",
    "spot_price" => 23100,
    "max_distance_pct" => 1.0,
    "min_premium" => 50,
    "max_premium" => 300
  },
  context
)
# => [{strike: 23200, option_type: "CE", ltp: 150, ...}]

# 4. Prepare trade intent
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
# => {trade_type: "OPTIONS_BUY", instrument: "NIFTY 23200 CE", note: "Await human confirmation", ...}
```

### Orders Tools (1) - Intent-Only

| Tool | Description | Arguments |
|------|-------------|-----------|
| `orders.prepare` | Prepare EQUITY/FUTURES trade intent | `exchange_segment`, `symbol`, `transaction_type`, `product_type`, `order_type`, `quantity`, `price` (optional), `trigger_price` (optional), `amo`, `bo_flag`, `co_flag`, `stop_loss`, `target` |

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
# => {trade_type: "EQUITY_FUTURES", instrument: "RELIANCE (NSE_EQ)", security_id: "1234", note: "Await human confirmation", ...}
```

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
MCP (prepare) → Intent → Rails/Human → Confirmation → dhanhq-client (execute)
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
├── server.rb          # Rack-based MCP HTTP server
├── router.rb          # Routes MCP calls to tools
├── tool_spec.rb       # MCP tool specifications (contract)
├── context.rb         # Dependency injection container
├── errors.rb          # Custom error classes
└── tools/
    ├── base.rb        # Base class for all tools
    ├── portfolio.rb   # Portfolio read-only tools
    ├── instrument.rb  # Instrument discovery & market data
    ├── orders.rb      # Order preparation (intent-only)
    └── options/
        ├── expiries.rb   # Option expiry list
        ├── chain.rb      # Option chain fetcher
        ├── selector.rb   # Rule-based strike selector
        └── prepare.rb    # Options trade preparation
```

### Adding New Tools

1. Add tool specification to `tool_spec.rb`
2. Create tool class inheriting from `Tools::Base`
3. Update `router.rb` to route the tool
4. Require the tool in `lib/dhanhq/mcp.rb`

**Example:**
```ruby
# 1. tool_spec.rb
{
  name: "portfolio.summary",
  description: "Get portfolio summary",
  input_schema: { type: "object", properties: {} }
}

# 2. tools/portfolio.rb
def summary
  {
    total_value: client.funds[:available_balance],
    holdings_count: client.holdings.count,
    positions_count: client.positions.count
  }
end

# 3. router.rb (already handles portfolio.* automatically via public_send)

# 4. Done! Tool is now available.
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
All tools receive a `Context` object with the `dhanhq-client` instance, enabling testability.

### 5. Protocol Adapter
`dhanhq-mcp` is a thin, safe adapter—not a reimplementation. It exposes a bounded subset of `dhanhq-client`.

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

- **DhanHQ Client Gem**: [dhanhq-client](https://github.com/shubhamtaywade82/dhanhq-client)
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
