# dhanhq-mcp

Ruby gem — MCP (Model Context Protocol) server exposing DhanHQ broker data and order execution as MCP tools. Supports both HTTP (Rack) and stdio transports.

## Stack

- Ruby gem (no Rails)
- Rack HTTP server (`rackup` / `webrick`) + stdio server
- `DhanHQ` gem (git source — dhanhq-client)
- RSpec + Timecop
- RuboCop

## Commands

```bash
bundle exec rspec
bundle exec rubocop
bundle exec rake

# Run server (stdio, for MCP clients like Claude Desktop)
bundle exec ruby -e "require 'dhanhq/mcp'; Dhanhq::Mcp::StdioServer.new.run"

# Run server (HTTP)
bundle exec rackup
```

## Architecture

```
lib/dhanhq/mcp/
  server.rb             # Rack HTTP MCP server
  stdio_server.rb       # stdio MCP server (Claude Desktop / CLI)
  router.rb             # Routes MCP method calls to tools
  tools/
    base.rb             # Tool base class
    orders.rb           # Order placement + management tools
    portfolio.rb        # Holdings + positions tools
    instrument.rb       # Instrument lookup tools
    options/            # Option chain tools
    stream/             # Streaming market data tools
  risk/                 # Pre-execution risk checks
  context.rb            # Request context (auth, session)
  validator.rb          # Input validation
  tool_spec.rb          # Tool schema definitions
  prompt_spec.rb        # Prompt template definitions
  resource_spec.rb      # Resource endpoint definitions
```

## Key rules

- DhanHQ v2 **only** — no Delta Exchange references
- Risk checks in `risk/` must run before any order tool executes
- Tools are stateless — no instance state between calls
- Never call live DhanHQ API in tests (WebMock all HTTP)
- stdio and HTTP servers share the same router — test the router, not the transport
