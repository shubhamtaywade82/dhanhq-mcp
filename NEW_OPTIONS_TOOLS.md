# New Options Analysis Tools - Implementation Summary

## ✅ Implemented Tools (Phase 1 - Critical)

Five new critical tools have been implemented for enhanced options buying analysis:

### 1. `option.filter_chain` - Advanced Chain Filtering

**Purpose:** Filter option chain by multiple criteria (OI, volume, IV, Greeks, premium)

**Usage:**
```ruby
{
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "expiry": "2026-01-27",
  "spot_price": 25048.65,
  "filters": {
    "min_oi": 100000,
    "min_volume": 10000,
    "max_iv": 25,
    "min_delta": 0.3,
    "max_delta": 0.7,
    "premium_range": [50, 300],
    "option_type": "CE",
    "max_distance_pct": 2.0
  },
  "sort_by": "volume",
  "limit": 10
}
```

**Returns:** Array of filtered options with full details (strike, premium, OI, volume, IV, Greeks)

---

### 2. `option.risk_reward` - Risk-Reward Calculator

**Purpose:** Calculate max profit, max loss, breakeven, risk-reward ratio

**Usage:**
```ruby
{
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "quantity": 50,
  "spot_price": 25048.65
}
```

**Returns:**
```ruby
{
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "quantity": 50,
  "spot_price": 25048.65,
  "max_profit": 15000.0,
  "max_loss": 7500.0,
  "breakeven": 25350.0,
  "risk_reward_ratio": 2.0,
  "intrinsic_value": 0.0,
  "time_value": 150.0
}
```

---

### 3. `option.probability` - Probability Analysis

**Purpose:** Calculate probability of profit, ITM, breakeven using Black-Scholes model

**Usage:**
```ruby
{
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "expiry": "2026-01-27",
  "spot_price": 25048.65,
  "iv": 0.18
}
```

**Returns:**
```ruby
{
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "spot_price": 25048.65,
  "iv": 0.18,
  "days_to_expiry": 4,
  "breakeven": 25350.0,
  "prob_itm": 28.5,
  "prob_otm": 71.5,
  "prob_profit": 32.1,
  "interpretation": "LOW - High risk trade"
}
```

---

### 4. `option.theta_analysis` - Time Decay Analysis

**Purpose:** Show how premium decays over remaining days to expiry

**Usage:**
```ruby
{
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "expiry": "2026-01-27",
  "spot_price": 25048.65,
  "days_ahead": [4, 3, 2, 1, 0]
}
```

**Returns:**
```ruby
{
  "strike": 25200,
  "option_type": "CE",
  "current_premium": 150.0,
  "days_to_expiry": 4,
  "current_theta": -12.5,
  "daily_decay_avg": 12.5,
  "decay_projection": [
    {
      "days_remaining": 4,
      "projected_premium": 150.0,
      "decay_amount": 0.0,
      "decay_pct": 0.0
    },
    {
      "days_remaining": 3,
      "projected_premium": 137.5,
      "decay_amount": 12.5,
      "decay_pct": 8.33
    },
    {
      "days_remaining": 2,
      "projected_premium": 112.5,
      "decay_amount": 37.5,
      "decay_pct": 25.0
    },
    {
      "days_remaining": 1,
      "projected_premium": 75.0,
      "decay_amount": 75.0,
      "decay_pct": 50.0
    },
    {
      "days_remaining": 0,
      "projected_premium": 0.0,
      "decay_amount": 150.0,
      "decay_pct": 100.0
    }
  ],
  "warning": "High time decay risk - consider exiting early"
}
```

---

### 5. `option.iv_metrics` - IV Percentile & Rank

**Purpose:** Calculate IV percentile and rank to determine if options are expensive/cheap

**Usage:**
```ruby
{
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "expiry": "2026-01-27",
  "spot_price": 25048.65
}
```

**Returns:**
```ruby
{
  "atm_iv": 18.5,
  "iv_percentile": 45.2,
  "iv_rank": 38.7,
  "iv_min": 12.0,
  "iv_max": 35.0,
  "iv_avg": 20.2,
  "recommendation": "IV is MODERATE - Neutral for buying options"
}
```

---

## Complete Workflow Example

### Step 1: Get IV Metrics
```ruby
iv_metrics = option.iv_metrics({
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "expiry": "2026-01-27"
})
# Check if IV is low (good for buying) or high (expensive)
```

### Step 2: Filter Chain for Good Options
```ruby
options = option.filter_chain({
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "expiry": "2026-01-27",
  "filters": {
    "min_oi": 100000,
    "min_volume": 10000,
    "max_iv": 25,
    "premium_range": [50, 300]
  },
  "sort_by": "volume",
  "limit": 5
})
```

### Step 3: Analyze Risk-Reward for Each Option
```ruby
option.risk_reward({
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "quantity": 50
})
```

### Step 4: Check Probability
```ruby
option.probability({
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "expiry": "2026-01-27"
})
```

### Step 5: Analyze Time Decay
```ruby
option.theta_analysis({
  "exchange_segment": "IDX_I",
  "symbol": "NIFTY",
  "strike": 25200,
  "option_type": "CE",
  "premium": 150,
  "expiry": "2026-01-27"
})
```

---

## Key Features

### ✅ What These Tools Provide

1. **IV Analysis** - Know if options are cheap or expensive
2. **Probability Metrics** - Understand success likelihood
3. **Risk-Reward** - Calculate max profit/loss before trading
4. **Time Decay** - See how premium decays over time
5. **Advanced Filtering** - Find options matching your criteria

### 🎯 Use Cases

- **Before Buying:** Check IV percentile, probability, risk-reward
- **Option Selection:** Filter by liquidity, IV, Greeks
- **Risk Management:** Calculate max loss, breakeven points
- **Time Management:** Understand theta decay impact
- **Strategy Planning:** Evaluate multiple options before choosing

---

## Implementation Details

### Files Created
- `lib/dhanhq/mcp/tools/options/filter_chain.rb`
- `lib/dhanhq/mcp/tools/options/risk_reward.rb`
- `lib/dhanhq/mcp/tools/options/probability.rb`
- `lib/dhanhq/mcp/tools/options/theta_analysis.rb`
- `lib/dhanhq/mcp/tools/options/iv_metrics.rb`

### Files Updated
- `lib/dhanhq/mcp/router.rb` - Added routes for new tools
- `lib/dhanhq/mcp/tool_spec.rb` - Added tool specifications

### Dependencies
- `date` gem (for date calculations in probability and theta_analysis)

---

## Next Steps (Phase 2)

The following tools are planned for Phase 2:
- `option.strategy` - Multi-leg strategy builder
- `option.put_call_ratio` - Market sentiment indicator
- `option.position_size` - Risk-based position sizing
- `option.compare_expiries` - Compare same strike across expiries

---

## Notes

- All tools follow the existing codebase patterns
- Tools use DhanHQ API data where available
- Calculations use simplified models (Black-Scholes approximations)
- IV percentile uses current chain data (historical IV data would improve accuracy)
- Tools are read-only (no execution, only analysis)

---

## Testing

To test the new tools:

```bash
# Test filter_chain
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"option.filter_chain","arguments":{"exchange_segment":"IDX_I","symbol":"NIFTY","expiry":"2026-01-27","filters":{"min_oi":100000},"limit":5}}}' | bundle exec ruby bin/dhanhq-mcp-stdio

# Test risk_reward
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"option.risk_reward","arguments":{"exchange_segment":"IDX_I","symbol":"NIFTY","strike":25200,"option_type":"CE","premium":150,"quantity":50}}}' | bundle exec ruby bin/dhanhq-mcp-stdio

# Test probability
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"option.probability","arguments":{"exchange_segment":"IDX_I","symbol":"NIFTY","strike":25200,"option_type":"CE","premium":150,"expiry":"2026-01-27"}}}' | bundle exec ruby bin/dhanhq-mcp-stdio

# Test theta_analysis
echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"option.theta_analysis","arguments":{"exchange_segment":"IDX_I","symbol":"NIFTY","strike":25200,"option_type":"CE","premium":150,"expiry":"2026-01-27"}}}' | bundle exec ruby bin/dhanhq-mcp-stdio

# Test iv_metrics
echo '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"option.iv_metrics","arguments":{"exchange_segment":"IDX_I","symbol":"NIFTY","expiry":"2026-01-27"}}}' | bundle exec ruby bin/dhanhq-mcp-stdio
```

---

**Status:** ✅ Phase 1 Complete - All critical tools implemented and ready for use!
