# Instrument Tool - Field Reference

## instrument.find

Returns complete instrument details including all critical fields for trading.

### Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `exchange_segment` | string | ✅ Yes | Exchange segment (e.g., "NSE_EQ", "IDX_I", "NSE_FNO") |
| `symbol` | string | ✅ Yes | Trading symbol to search for |

### Return Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `security_id` | string | **Critical** - Unique security identifier used in all API calls | `"2885"` |
| `symbol` | string | Trading symbol name | `"RELIANCE INDUSTRIES LTD"` |
| `display_name` | string | **Important** - Human-readable company/instrument name | `"Reliance Industries"` |
| `underlying_symbol` | string | **Important** - Underlying symbol (for derivatives/options) | `"RELIANCE"` |
| `exchange_segment` | string | **Critical** - Exchange and segment identifier | `"NSE_EQ"` |
| `segment` | string | **Important** - Segment code | `"E"` (Equity) |
| `instrument` | string | **Critical** - Instrument type for API calls | `"EQUITY"`, `"INDEX"`, `"FUTIDX"` |
| `instrument_type` | string | Instrument classification | `"ES"` (Equity Stock) |
| `expiry_flag` | string | Whether instrument has expiry | `"N"` or `"Y"` |

### Why These Fields Matter

#### Critical for Trading Operations

1. **`security_id`** - Required for:
   - Market data API calls (LTP, quote, OHLC)
   - Historical data requests
   - Option chain queries
   - Order placement

2. **`exchange_segment`** - Required for:
   - All API operations
   - Identifying the trading venue
   - Routing orders correctly

3. **`instrument`** - Required for:
   - Historical data API (must specify instrument type)
   - Proper API endpoint selection

#### Important for User Experience

4. **`display_name`** - Best for:
   - Showing to users (more readable than symbol)
   - UI displays
   - Logging and reports

5. **`underlying_symbol`** - Important for:
   - Options trading (finding the base symbol)
   - Derivatives identification
   - Symbol matching in equity vs F&O

6. **`segment`** - Useful for:
   - Quick segment identification
   - Filtering instruments
   - Understanding market type

### Example Usage

```ruby
# Find RELIANCE stock
result = instrument.find(
  exchange_segment: "NSE_EQ",
  symbol: "RELIANCE"
)

# Returns:
{
  "security_id": "2885",              # Use this for API calls
  "symbol": "RELIANCE INDUSTRIES LTD", # Official symbol
  "display_name": "Reliance Industries", # Show this to users
  "underlying_symbol": "RELIANCE",     # Use for option lookups
  "exchange_segment": "NSE_EQ",        # Trading venue
  "segment": "E",                      # Equity segment
  "instrument": "EQUITY",              # Instrument type
  "instrument_type": "ES",             # Equity Stock
  "expiry_flag": "NA"                  # No expiry
}

# Now use security_id for market data
ltp = instrument.ltp(
  exchange_segment: "NSE_EQ",
  symbol: "RELIANCE"  # Will internally use security_id: "2885"
)
```

### Real-World Examples

#### Index Instrument
```json
{
  "security_id": "13",
  "symbol": "NIFTY",
  "display_name": "Nifty 50",
  "underlying_symbol": "NIFTY",
  "exchange_segment": "IDX_I",
  "segment": "I",
  "instrument": "INDEX",
  "instrument_type": "INDEX",
  "expiry_flag": "N"
}
```

#### Equity Stock
```json
{
  "security_id": "11536",
  "symbol": "TCS LTD",
  "display_name": "Tata Consultancy Services Ltd",
  "underlying_symbol": "TCS",
  "exchange_segment": "NSE_EQ",
  "segment": "E",
  "instrument": "EQUITY",
  "instrument_type": "ES",
  "expiry_flag": "NA"
}
```

#### Future Contract
```json
{
  "security_id": "52175",
  "symbol": "NIFTY 26 FEB 2026 FUT",
  "display_name": "NIFTY FEB FUT",
  "underlying_symbol": "NIFTY",
  "exchange_segment": "NSE_FNO",
  "segment": "D",
  "instrument": "FUTIDX",
  "instrument_type": "FUTIDX",
  "expiry_flag": "Y"
}
```

## Best Practices

1. **Always store `security_id`** - It's the primary key for all operations
2. **Show `display_name` to users** - More readable than technical symbols
3. **Use `underlying_symbol` for options** - Essential for option chain lookups
4. **Check `expiry_flag`** - Know if instrument has time-limited validity
5. **Validate `exchange_segment`** - Ensure you're trading on the right venue

## Related Tools

- `instrument.info` - Get trading permissions and risk metadata
- `instrument.ltp` - Get last traded price (uses security_id internally)
- `option.expiries` - Get expiry dates (uses underlying_symbol)
- `option.chain` - Get option chain (uses security_id and underlying_symbol)
