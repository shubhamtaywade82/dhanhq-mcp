# DhanHQ API Rate Limits

## Critical Rule

**ALWAYS wait 1 second between consecutive API calls**

```ruby
# ✅ CORRECT
result1 = instrument.ltp(...)
sleep 1  # Rate limit: 1 sec between API calls
result2 = instrument.quote(...)
```

```ruby
# ❌ WRONG - Will trigger 429 Rate Limit Error
result1 = instrument.ltp(...)
result2 = instrument.quote(...)  # Too fast! Will fail
```

## API Call Categories

### Requires Rate Limiting (1 sec delay)

All authenticated API calls require 1-second delays:

| Tool | Rate Limited? | Why |
|------|---------------|-----|
| `instrument.ltp` | ✅ Yes | Live API call |
| `instrument.quote` | ✅ Yes | Live API call |
| `instrument.ohlc` | ✅ Yes | Live API call |
| `instrument.daily` | ✅ Yes | Historical API call |
| `instrument.intraday` | ✅ Yes | Historical API call |
| `option.expiries` | ✅ Yes | Option API call |
| `option.chain` | ✅ Yes | Option API call |
| `portfolio.holdings` | ✅ Yes | Account API call |
| `portfolio.positions` | ✅ Yes | Account API call |
| `portfolio.funds` | ✅ Yes | Account API call |
| `portfolio.orders` | ✅ Yes | Account API call |
| `portfolio.trades` | ✅ Yes | Account API call |

### No Rate Limiting Required

These operations don't hit the API:

| Tool | Rate Limited? | Why |
|------|---------------|-----|
| `instrument.find` | ❌ No | Uses public CSV (cached) |
| `instrument.info` | ❌ No | Uses public CSV (cached) |
| `option.select` | ❌ No | Processes data client-side |
| `option.prepare` | ❌ No | Intent only, no API call |
| `orders.prepare` | ❌ No | Intent only, no API call |

## Error: 429 Rate Limit

If you see this error:

```
DhanHQ::RateLimitError: 429: Unknown error
```

**Solution:** Add `sleep 1` between consecutive API calls.

## Implementation Examples

### Correct: Test Script with Rate Limits

```ruby
# bin/test-market
puts "=== Testing instrument.ltp ==="
result = tool.ltp(...)
puts result

sleep 1  # Required!

puts "=== Testing instrument.quote ==="
result = tool.quote(...)
puts result

sleep 1  # Required!

puts "=== Testing instrument.ohlc ==="
result = tool.ohlc(...)
puts result
```

### Correct: Production Code with Multiple Calls

```ruby
# Fetching multiple instruments
instruments = ["RELIANCE", "TCS", "INFY"]

instruments.each do |symbol|
  ltp = Instrument.new(context).ltp(
    exchange_segment: "NSE_EQ",
    symbol: symbol
  )
  
  puts "#{symbol}: #{ltp}"
  
  sleep 1  # Rate limit between each call
end
```

### Correct: Option Chain Analysis

```ruby
# Get expiries
expiries = Options::Expiries.new(context).call(
  exchange_segment: "IDX_I",
  symbol: "NIFTY"
)

sleep 1  # Required!

# Get chain for first expiry
chain = Options::Chain.new(context).call(
  exchange_segment: "IDX_I",
  symbol: "NIFTY",
  expiry: expiries.first
)

# No sleep needed here - client-side processing
selected = Options::Selector.new(context).call(
  chain: chain,
  spot_price: 21_000,
  direction: "BULLISH"
)
```

### Correct: Portfolio Data Collection

```ruby
# Get all portfolio data with proper delays
holdings = Portfolio.new(context).holdings
sleep 1

positions = Portfolio.new(context).positions
sleep 1

funds = Portfolio.new(context).funds
sleep 1

orders = Portfolio.new(context).orders
sleep 1

trades = Portfolio.new(context).trades
```

## Rate Limit Details

| Aspect | Value |
|--------|-------|
| **Minimum delay** | 1 second |
| **Applies to** | All authenticated API endpoints |
| **Error code** | 429 |
| **Error type** | `DhanHQ::RateLimitError` |
| **Recommended** | Add 1.5 sec delay for safety margin |

## Best Practices

1. **Always add delays** - Even if you think it's unnecessary
2. **Use explicit sleep** - Don't rely on processing time
3. **Log delays** - Help debug timing issues
4. **Batch wisely** - Group related calls with delays between
5. **Cache results** - Avoid redundant API calls

## Testing with Rate Limits

Our test scripts now include proper rate limiting:

```bash
$ bin/test-market      # 3 API calls with 2 sleep(1) delays
$ bin/test-options     # 2 API calls with 1 sleep(1) delay
$ bin/test-portfolio   # 5 API calls with 4 sleep(1) delays
```

## When Rate Limits Don't Apply

**Public CSV operations** (instrument.find, instrument.info):
- These read from cached CSV files
- No API calls made
- No rate limiting needed
- Can be called rapidly

```ruby
# ✅ This is fine - no API calls
100.times do |i|
  inst = Instrument.new(context).find(
    exchange_segment: "NSE_EQ",
    symbol: "RELIANCE"
  )
end
```

## Summary

- ✅ **DO:** Add `sleep 1` between all authenticated API calls
- ✅ **DO:** Test with delays to match production behavior
- ✅ **DO:** Cache results to minimize API calls
- ❌ **DON'T:** Make rapid consecutive API calls
- ❌ **DON'T:** Assume processing time is enough delay
- ❌ **DON'T:** Ignore 429 errors - fix the code!

---

**Last Updated:** 2026-01-17  
**Status:** ✅ All test scripts updated with rate limiting
