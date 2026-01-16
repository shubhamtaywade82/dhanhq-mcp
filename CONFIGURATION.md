# Configuration Guide

## Environment Variables

The dhanhq-mcp gem uses `.env` files for configuration following DhanHQ best practices.

### Required Variables

| Variable | Purpose | Required For |
|----------|---------|--------------|
| `CLIENT_ID` | Trading account client ID issued by Dhan | API calls (portfolio, market data, options) |
| `ACCESS_TOKEN` | API access token from Dhan console | API calls (portfolio, market data, options) |

### Optional Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `DHAN_LOG_LEVEL` | Logging level (DEBUG, INFO, WARN, ERROR) | `INFO` |
| `DHAN_BASE_URL` | API base URL override | `https://api.dhan.co` |
| `DHAN_CONNECT_TIMEOUT` | Connection timeout in seconds | `10` |
| `DHAN_READ_TIMEOUT` | Read timeout in seconds | `30` |
| `DHAN_WRITE_TIMEOUT` | Write timeout in seconds | `30` |

## Setup Instructions

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your credentials:**
   ```bash
   CLIENT_ID=your_client_id_here
   ACCESS_TOKEN=your_access_token_here
   DHAN_LOG_LEVEL=INFO
   ```

3. **Get your credentials:**
   - Login to [DhanHQ](https://dhanhq.co/)
   - Navigate to API Settings
   - Generate or copy your **Client ID** and **Access Token**

## Configuration in Code

All bin scripts use the standard DhanHQ configuration pattern:

```ruby
require "dotenv/load"
require "dhan_hq"

# Configure from environment
DhanHQ.configure_with_env
DhanHQ.logger.level = (ENV["DHAN_LOG_LEVEL"] || "INFO").upcase.then { |level| Logger.const_get(level) }
```

### What `configure_with_env` Does

The `DhanHQ.configure_with_env` method:
1. Reads `CLIENT_ID` and `ACCESS_TOKEN` from ENV
2. Raises an error if either is missing
3. Configures the DhanHQ client automatically
4. Sets up proper authentication headers

## Tool-Specific Requirements

| Tool Category | Requires Auth? | Notes |
|--------------|----------------|-------|
| `instrument.find` | ❌ No | Uses public CSV data |
| `instrument.info` | ❌ No | Uses public CSV data |
| `instrument.ltp/quote/ohlc` | ✅ Yes | Live market data API |
| `instrument.daily/intraday` | ✅ Yes | Historical data API |
| `option.expiries` | ✅ Yes | Option chain API |
| `option.chain` | ✅ Yes | Option chain API |
| `option.select` | ✅ Yes | Uses option chain data |
| `option.prepare` | ❌ No | Intent-only (validation) |
| `orders.prepare` | ❌ No | Intent-only (validation) |
| `portfolio.*` | ✅ Yes | Portfolio & account APIs |

## Testing

### Without Authentication (Public Data)
```bash
bin/test-instrument  # Uses public CSV, no .env needed
```

### With Authentication (API Calls)
```bash
# Requires .env configuration
bin/test-market      # Market data tools
bin/test-options     # Options tools
bin/test-orders      # Order preparation
bin/test-portfolio   # Portfolio tools
```

## Security Notes

- The `.env` file is automatically excluded from git (see `.gitignore`)
- Never commit your actual credentials
- Keep `.env.example` updated as a template
- Rotate your `ACCESS_TOKEN` periodically for security

## Troubleshooting

### Error: "CLIENT_ID not found"
- Make sure `.env` file exists in the project root
- Verify `CLIENT_ID=your_value` is set (no quotes needed)
- Check that dotenv gem is installed: `bundle install`

### Error: "ACCESS_TOKEN not found"
- Make sure `.env` file exists in the project root
- Verify `ACCESS_TOKEN=your_value` is set
- Get a fresh token from DhanHQ console if expired

### Error: "401 Unauthorized"
- Your `ACCESS_TOKEN` may be expired or invalid
- Generate a new token from DhanHQ console
- Make sure CLIENT_ID matches the token

## Reference

For more details, see:
- [DhanHQ API Documentation](https://dhanhq.co/docs/v2/)
- [dhanhq-client Configuration](https://github.com/shubhamtaywade82/dhanhq-client#configuration)
