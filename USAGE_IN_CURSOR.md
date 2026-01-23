# Using DhanHQ MCP Tools in Cursor Chats

Once your MCP server is configured and connected to Cursor, all 17 tools are **automatically available** to the AI assistant. You don't need to manually invoke them - just ask naturally!

## How It Works

1. **Automatic Discovery**: Cursor discovers all available tools when the MCP server connects
2. **Natural Language**: Ask questions or make requests in plain English
3. **AI Decides**: The AI automatically selects and invokes the appropriate tools
4. **Results Displayed**: Tool results appear in the chat with visual indicators

## Example Conversations

### Portfolio Queries

**You:**
```
What are my current holdings?
```

**AI will automatically use:** `portfolio.holdings`

---

**You:**
```
Show me my available funds and current positions
```

**AI will automatically use:** `portfolio.funds` and `portfolio.positions`

---

**You:**
```
What orders do I have pending?
```

**AI will automatically use:** `portfolio.orders`

---

### Market Data Queries

**You:**
```
What's the current price of RELIANCE?
```

**AI will automatically use:** `instrument.ltp` or `instrument.quote`

---

**You:**
```
Get me the full market quote for NIFTY on NSE
```

**AI will automatically use:** `instrument.quote` with `exchange_segment: "IDX_I"`, `symbol: "NIFTY"`

---

**You:**
```
Show me the OHLC data for RELIANCE
```

**AI will automatically use:** `instrument.ohlc`

---

**You:**
```
Get daily candles for RELIANCE from Jan 1 to Jan 20
```

**AI will automatically use:** `instrument.daily` with date range

---

### Instrument Discovery

**You:**
```
Find the instrument details for RELIANCE on NSE
```

**AI will automatically use:** `instrument.find`

---

**You:**
```
What are the trading permissions for NIFTY options?
```

**AI will automatically use:** `instrument.info`

---

### Options Trading

**You:**
```
What expiries are available for NIFTY options?
```

**AI will automatically use:** `option.expiries`

---

**You:**
```
Show me the option chain for NIFTY expiring on 2026-01-30
```

**AI will automatically use:** `option.chain`

---

**You:**
```
I'm bullish on NIFTY at 23100. Find me a good call option strike within 1% distance, premium between 50-300
```

**AI will automatically use:** `option.select` with your criteria

---

**You:**
```
Prepare a BUY order for 50 NIFTY 23200 CE expiring 2026-01-30 with stop loss at 100 and target at 200
```

**AI will automatically use:** `option.prepare` to create the trade intent

---

### Equity/Futures Orders

**You:**
```
Prepare a market buy order for 10 shares of RELIANCE, intraday product
```

**AI will automatically use:** `orders.prepare`

---

**You:**
```
I want to sell 5 shares of TCS with a limit price of 3500, CNC product
```

**AI will automatically use:** `orders.prepare` with your specifications

---

## What You'll See

When tools are invoked, Cursor will show:

1. **Tool Invocation Indicator**: Visual indicator that a tool is being called
2. **Tool Name**: Which tool is being used (e.g., `portfolio.holdings`)
3. **Tool Result**: The data returned from the tool
4. **AI Response**: The AI's interpretation and presentation of the results

## Tips for Best Results

### Be Specific
✅ **Good:** "Get the last traded price for RELIANCE on NSE"
❌ **Vague:** "Get price"

### Include Context
✅ **Good:** "Show me NIFTY option expiries for index options"
❌ **Missing context:** "Show expiries" (which symbol? which segment?)

### Use Natural Language
✅ **Good:** "What's my portfolio value?"
✅ **Also good:** "Show me my holdings"
❌ **Unnecessary:** "Call portfolio.holdings tool"

### Chain Requests
You can ask follow-up questions:
```
You: What's the price of RELIANCE?
AI: [Uses instrument.quote, shows price]

You: Prepare a buy order for 10 shares
AI: [Uses orders.prepare with the symbol from context]
```

## Troubleshooting

### Tools Not Appearing

1. **Check MCP Connection**: Look for "Found X tools" in Cursor's MCP logs
2. **Verify Server**: Ensure `bundle exec ruby bin/dhanhq-mcp-stdio` runs without errors
3. **Check Environment**: Make sure `CLIENT_ID` and `ACCESS_TOKEN` are set

### Tool Errors

If a tool fails:
- The AI will show the error message
- Check Cursor's MCP logs for details
- Verify your API credentials are valid
- Ensure the instrument/symbol exists

### Rate Limiting

Some tools have rate limits:
- Portfolio tools: ~1 request/second
- Market data: ~1 request/second
- Options data: ~1 request/second

If you hit limits, wait a moment and try again.

## Advanced: Explicit Tool Invocation

While not necessary, you can be explicit:

**You:**
```
Use the portfolio.holdings tool to get my current holdings
```

The AI will still invoke it the same way, but being explicit can help if the AI is unsure which tool to use.

## Example Full Workflow

**You:**
```
I want to trade NIFTY options. First, show me available expiries.
```

**AI:**
- Uses `option.expiries` for NIFTY
- Shows available expiry dates

**You:**
```
Get the option chain for the nearest expiry
```

**AI:**
- Uses `option.chain` for the first expiry
- Shows all strikes with prices

**You:**
```
I'm bullish. Find me a good call option near the current spot price of 23100
```

**AI:**
- Uses `option.select` with BULLISH direction
- Filters by your criteria
- Returns matching options

**You:**
```
Prepare a buy order for 50 contracts of the first option you found
```

**AI:**
- Uses `option.prepare` with the selected option details
- Creates trade intent (no execution)
- Shows you the prepared order for review

---

**Remember**: Just talk naturally! The AI handles all the tool invocations automatically based on your requests.
