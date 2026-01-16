# Model Object Serialization

## Problem

Portfolio tools were returning Ruby model objects instead of JSON-serializable hashes:

```ruby
# ❌ WRONG - Returns object references
portfolio.positions
# => ["#<DhanHQ::Models::Position:0x00007f617f1a14d0>", ...]

portfolio.funds  
# => "#<DhanHQ::Models::Funds:0x00007fbb69801de0>"
```

This causes issues when:
1. Sending responses via MCP protocol (requires JSON)
2. Testing output in terminal
3. Debugging/inspecting data
4. Using data in client applications

## Solution

Added automatic serialization to convert model objects to hashes:

```ruby
# ✅ CORRECT - Returns serializable hashes
portfolio.positions
# => [{"dhan_client_id"=>"1104216308", "trading_symbol"=>"NIFTY", ...}]

portfolio.funds
# => {"available_balance"=>50000.0, "sod_limit"=>70000.0, ...}
```

## Implementation

### Serialization Methods

Added private helper methods to `Portfolio` tool:

```ruby
def serialize_collection(collection)
  collection.map { |item| serialize_object(item) }
end

def serialize_object(obj)
  return obj if obj.is_a?(Hash)           # Already a hash
  return obj.to_h if obj.respond_to?(:to_h)  # Has to_h method
  return obj.attributes if obj.respond_to?(:attributes)  # Has attributes
  obj  # Fallback: return as-is
end
```

### DhanHQ Model Serialization

DhanHQ models use different serialization methods:

| Model | Serialization Method | Available? |
|-------|---------------------|------------|
| `Holding` | `to_h` | ✅ Yes |
| `Position` | `attributes` | ✅ Yes |
| `Funds` | `attributes` | ✅ Yes |
| `Order` | `attributes` | ✅ Yes |
| `Trade` | `attributes` | ✅ Yes |

**Note:** All `BaseModel` subclasses have an `attributes` accessor that returns the underlying hash.

### Updated Methods

All portfolio methods now return serialized hashes:

```ruby
def holdings
  serialize_collection(DhanHQ::Models::Holding.all)
end

def positions
  serialize_collection(DhanHQ::Models::Position.all)
end

def funds
  serialize_object(DhanHQ::Models::Funds.fetch)
end

def orders
  serialize_collection(DhanHQ::Models::Order.all)
end

def trades
  serialize_collection(DhanHQ::Models::Trade.today)
end
```

## Verification

### Test Output

**Before:**
```
📊 Testing: portfolio.positions
   Result: ["#<DhanHQ::Models::Position:0x00007f617f1a14d0>"]
```

**After:**
```
📊 Testing: portfolio.positions
   Result: [{"dhan_client_id"=>"1104216308", "trading_symbol"=>"NIFTY-Jan2026-25650-PE", ...}]
```

### RSpec Tests

Added tests to verify serialization:

```ruby
it "fetches positions from DhanHQ Models and serializes to hashes" do
  position_obj = double("position", attributes: { symbol: "NIFTY", quantity: 50 })
  allow(DhanHQ::Models::Position).to receive(:all).and_return([position_obj])

  result = tool.positions

  expect(result).to eq([{ symbol: "NIFTY", quantity: 50 }])
  expect(result.first).to be_a(Hash)  # Verify it's a hash, not an object
end
```

### Test Suite

```bash
$ bundle exec rspec
87 examples, 0 failures
Line Coverage: 99.66% (297/298)
Branch Coverage: 98.33% (59/60)
```

## Benefits

1. **JSON Compatibility** - Can be serialized to JSON for MCP protocol
2. **Debuggability** - Human-readable output in tests and logs
3. **Client Compatibility** - Works with any JSON client
4. **Consistency** - All tools return consistent hash format
5. **Flexibility** - Handles both object and hash responses

## Usage Examples

### Holdings
```ruby
holdings = portfolio.holdings
# => [
#   {
#     "exchange" => "NSE",
#     "trading_symbol" => "RELIANCE",
#     "security_id" => "2885",
#     "total_qty" => 10,
#     "avg_cost_price" => 2500.0
#   }
# ]
```

### Positions
```ruby
positions = portfolio.positions
# => [
#   {
#     "dhan_client_id" => "1104216308",
#     "trading_symbol" => "NIFTY-Jan2026-25650-PE",
#     "security_id" => "47612",
#     "position_type" => "LONG",
#     "buy_qty" => 50,
#     "net_qty" => 50,
#     "unrealized_profit" => 1250.0
#   }
# ]
```

### Funds
```ruby
funds = portfolio.funds
# => {
#   "dhan_client_id" => "1104216308",
#   "available_balance" => 862.95,
#   "sod_limit" => 70000.0,
#   "utilized_amount" => 69137.05,
#   "withdrawable_balance" => 0.0
# }
```

### Orders
```ruby
orders = portfolio.orders
# => [
#   {
#     "order_id" => "ORD123",
#     "dhan_client_id" => "1104216308",
#     "order_status" => "TRADED",
#     "trading_symbol" => "TCS",
#     "quantity" => 1,
#     "price" => 3500.0
#   }
# ]
```

### Trades
```ruby
trades = portfolio.trades
# => [
#   {
#     "trade_id" => "TRD456",
#     "order_id" => "ORD123",
#     "trading_symbol" => "TCS",
#     "quantity" => 1,
#     "trade_price" => 3505.0
#   }
# ]
```

## Technical Details

### Why `attributes` vs `to_h`?

- `Holding` model explicitly defines `to_h` with specific fields
- Other models use the generic `attributes` accessor from `BaseModel`
- Both return hashes, making them JSON-serializable
- Our code handles both gracefully via `respond_to?` checks

### Serialization Priority

The `serialize_object` method checks in this order:

1. **Is it already a Hash?** → Return as-is
2. **Does it respond to `to_h`?** → Call `to_h`
3. **Does it respond to `attributes`?** → Call `attributes`
4. **Fallback** → Return object as-is (shouldn't happen)

This ensures compatibility with any model format.

## Related Files

- **Implementation:** `lib/dhanhq/mcp/tools/portfolio.rb`
- **Tests:** `spec/dhanhq/mcp/tools/portfolio_spec.rb`
- **DhanHQ Models:** `/home/nemesis/project/dhanhq-client/lib/DhanHQ/models/`

---

**Issue:** Object references in output  
**Status:** ✅ Fixed  
**Date:** 2026-01-17  
**Impact:** All portfolio tools now return JSON-serializable hashes
