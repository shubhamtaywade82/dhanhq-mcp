# DhanHQ API Alignment Guide

This document tracks how `dhanhq-mcp` aligns with the `dhanhq-client` gem API.

## ✅ 100% API Aligned

All tools now correctly use the `dhanhq-client` gem's API patterns.

## Critical Alignment Points

### 1. Instrument Model - Use `symbol_name` (NOT `symbol`)

**Correct:**
```ruby
inst = DhanHQ::Models::Instrument.find("NSE_EQ", "RELIANCE")
puts inst.symbol_name  # "RELIANCE INDUSTRIES LTD"
```

**Wrong:**
```ruby
puts inst.symbol  # NoMethodError!
```

**Files Updated:**
- `lib/dhanhq/mcp/tools/instrument.rb` - Returns `symbol_name` in responses
- `lib/dhanhq/mcp/tools/orders.rb` - Uses `inst.symbol_name` for display
- `lib/dhanhq/mcp/tools/options/prepare.rb` - Uses `inst.symbol_name` for display

### 2. Portfolio Models - Use Class Methods (NOT instance methods)

**Correct:**
```ruby
# Holdings
holdings = DhanHQ::Models::Holding.all

# Positions
positions = DhanHQ::Models::Position.all

# Funds
funds = DhanHQ::Models::Funds.fetch

# Orders
orders = DhanHQ::Models::Order.all

# Trades (today's trades)
trades = DhanHQ::Models::Trade.today
```

**Wrong:**
```ruby
client = DhanHQ::Client.new(access_token: token)
client.holdings  # NoMethodError!
```

**Files Updated:**
- `lib/dhanhq/mcp/tools/portfolio.rb` - All methods use `DhanHQ::Models` directly

### 3. Instrument Attributes - Complete Field Mapping

| dhanhq-client Attribute | Description | Example |
|------------------------|-------------|---------|
| `security_id` | Unique identifier (string) | `"2885"` |
| `symbol_name` | Trading symbol | `"RELIANCE INDUSTRIES LTD"` |
| `display_name` | Human-readable name | `"Reliance Industries"` |
| `underlying_symbol` | Base symbol (for derivatives) | `"RELIANCE"` |
| `exchange_segment` | Exchange + segment | `"NSE_EQ"` |
| `segment` | Segment code | `"E"` |
| `instrument` | Instrument type | `"EQUITY"`, `"INDEX"`, `"FUTIDX"` |
| `instrument_type` | Type classification | `"ES"`, `"INDEX"`, `"FUTIDX"` |
| `expiry_flag` | Has expiry? | `"N"`, `"Y"`, `"NA"` |
| `isin` | ISIN code | `"INE002A01018"` |
| `buy_sell_indicator` | Trading allowed? | `"A"`, `"N"` |
| `bracket_flag` | Bracket orders? | `"Y"`, `"N"` |
| `cover_flag` | Cover orders? | `"Y"`, `"N"` |
| `asm_gsm_flag` | ASM/GSM status | `"N"`, `"ASM"`, `"GSM"` |
| `asm_gsm_category` | ASM/GSM category | `"NONE"`, `"STAGE1"` |
| `mtf_leverage` | MTF leverage | `0.0` |
| `buy_co_min_margin_per` | Buy margin % | `0.0` |
| `sell_co_min_margin_per` | Sell margin % | `nil` or number |

### 4. Configuration - Use `DhanHQ.configure_with_env`

**Correct:**
```ruby
require "dotenv/load"
require "dhan_hq"

DhanHQ.configure_with_env
DhanHQ.logger.level = (ENV["DHAN_LOG_LEVEL"] || "INFO").upcase.then { |level| Logger.const_get(level) }
```

**Environment Variables Required:**
- `CLIENT_ID` - Your Dhan client ID
- `ACCESS_TOKEN` - Your API access token

**Files Updated:**
- `bin/dhanhq-mcp-stdio`
- `bin/test-options`
- `bin/test-market`
- `bin/test-orders`

### 5. Authentication Requirements

| Tool | Requires Auth? | Data Source |
|------|----------------|-------------|
| `instrument.find` | ❌ No | Public CSV |
| `instrument.info` | ❌ No | Public CSV |
| `instrument.ltp` | ✅ Yes | Live API |
| `instrument.quote` | ✅ Yes | Live API |
| `instrument.ohlc` | ✅ Yes | Live API |
| `instrument.daily` | ✅ Yes | Historical API |
| `instrument.intraday` | ✅ Yes | Historical API |
| `option.expiries` | ✅ Yes | Option API |
| `option.chain` | ✅ Yes | Option API |
| `option.select` | ✅ Yes | Uses option chain |
| `option.prepare` | ❌ No | Intent only |
| `orders.prepare` | ❌ No | Intent only |
| `portfolio.*` | ✅ Yes | Account API |

## Test Alignment

All RSpec tests properly stub the `dhanhq-client` API:

```ruby
# Instrument stubs
allow(DhanHQ::Models::Instrument).to receive(:find)
  .with("NSE_EQ", "RELIANCE")
  .and_return(instrument)
allow(instrument).to receive_messages(
  symbol_name: "RELIANCE",  # ← Correct attribute
  exchange_segment: "NSE_EQ",
  # ... other attributes
)

# Portfolio stubs
allow(DhanHQ::Models::Holding).to receive(:all).and_return([...])
allow(DhanHQ::Models::Position).to receive(:all).and_return([...])
allow(DhanHQ::Models::Funds).to receive(:fetch).and_return({...})
allow(DhanHQ::Models::Order).to receive(:all).and_return([...])
allow(DhanHQ::Models::Trade).to receive(:today).and_return([...])
```

## Verification

### Test Suite
```bash
$ bundle exec rspec
86 examples, 0 failures
Line Coverage: 99.66% (289/290)
Branch Coverage: 98.15% (53/54)
```

### Live API Tests
```bash
$ bin/test-instrument  # Public data, no auth needed
$ bin/test-orders      # Intent only, no auth needed
$ bin/test-market      # Requires .env with credentials
$ bin/test-options     # Requires .env with credentials
$ bin/test-portfolio   # Requires .env with credentials
```

### MCP Server
```bash
$ echo '{"method":"tools/call","params":{"name":"instrument.find","arguments":{"exchange_segment":"NSE_EQ","symbol":"RELIANCE"}}}' | bin/dhanhq-mcp-stdio
{
  "result": {
    "security_id": "2885",
    "symbol": "RELIANCE INDUSTRIES LTD",
    "display_name": "Reliance Industries",
    "underlying_symbol": "RELIANCE",
    "exchange_segment": "NSE_EQ",
    "segment": "E",
    "instrument": "EQUITY",
    "instrument_type": "ES",
    "expiry_flag": "NA"
  }
}
```

## Common Pitfalls (Now Fixed)

### ❌ WRONG: Using `symbol` instead of `symbol_name`
```ruby
inst.symbol  # NoMethodError!
```

### ✅ CORRECT: Using `symbol_name`
```ruby
inst.symbol_name  # "RELIANCE INDUSTRIES LTD"
```

### ❌ WRONG: Using client instance methods
```ruby
client.holdings  # NoMethodError!
```

### ✅ CORRECT: Using Model class methods
```ruby
DhanHQ::Models::Holding.all  # [...]
```

### ❌ WRONG: Missing configuration
```ruby
# Just requiring the gem isn't enough
require "dhan_hq"
DhanHQ::Models::Holding.all  # Error: base_url not configured
```

### ✅ CORRECT: Proper configuration
```ruby
require "dotenv/load"
require "dhan_hq"

DhanHQ.configure_with_env  # Reads CLIENT_ID and ACCESS_TOKEN from ENV
DhanHQ::Models::Holding.all  # Works!
```

## Reference

- **dhanhq-client gem**: `/home/nemesis/project/dhanhq-client`
- **DhanHQ API docs**: https://dhanhq.co/docs/v2/
- **Configuration guide**: `CONFIGURATION.md`
- **Instrument fields**: `INSTRUMENT_FIELDS.md`

---

**Last Updated:** 2026-01-17  
**Status:** ✅ 100% API Aligned  
**Test Coverage:** 99.66% line, 98.15% branch
