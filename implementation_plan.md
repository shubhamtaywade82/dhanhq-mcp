# DhanHQ Implementation Plan

This plan splits the work into two repositories:

- `dhanhq-client`: core SDK, models, contracts, market data, risk, agent primitives, and skills layer
- `dhanhq-mcp`: MCP transport, policy enforcement, tool adapters, and protocol glue

Current workspace access is writable only for `dhanhq-mcp`, so client-side changes are planned here and will need to be executed in the client repository workspace.

## Phase 1: `dhanhq-client`

- [ ] Audit the current core API surface against Dhan API v2 coverage
- [ ] Confirm model coverage for orders, positions, holdings, trades, funds, instrument, option chain, margin, statements, eDIS, super orders, forever orders, alerts, and historical data
- [ ] Identify missing typed primitives for market data and option analytics
- [ ] Identify missing risk primitives and validation contracts
- [ ] Confirm the current agent primitives: policy, tool registry, order preview
- [ ] Define the missing skills layer: skill registry, workflow registry, workflow execution, and built-in strategy skills
- [ ] Add or update specs for any new core primitives before MCP integration

## Phase 2: `dhanhq-mcp`

- [ ] Map MCP tools to the finalized `dhanhq-client` primitives
- [ ] Keep stdio as the primary transport and verify protocol correctness
- [ ] Enforce read / intent / write policy gates at the MCP boundary
- [ ] Ensure tool registry metadata matches the client capabilities and scopes
- [ ] Decide whether experimental transports stay in repo or are removed
- [ ] Add or update MCP specs for dispatch, prompts, resources, and error envelopes

## Execution Order

1. Finish `dhanhq-client` core and skills decisions first.
2. Lock the exported primitives and tool/skill registry shapes.
3. Wire `dhanhq-mcp` to those finalized shapes.
4. Verify both repos with focused specs.

## Working Rule

Only one item should be actively changed at a time. When a step is complete, mark it done before starting the next.
