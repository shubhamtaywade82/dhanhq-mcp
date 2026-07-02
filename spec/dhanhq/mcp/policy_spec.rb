# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Policy do
  describe "write-tool authorization" do
    let(:tool) { Dhanhq::Mcp::ToolRegistry.fetch("orders.place") }

    it "blocks write tools by default" do
      expect do
        described_class.default.authorize!(tool)
      end.to raise_error(Dhanhq::Mcp::Errors::PermissionDenied, /write scope/)
    end

    it "requires live trading even when write scope is present" do
      policy = described_class.new(allow_writes: true, allow_live_trading: false, scopes: %i[read_only intent_only write])

      expect do
        policy.authorize!(tool)
      end.to raise_error(Dhanhq::Mcp::Errors::PermissionDenied, /LIVE_TRADING=true/)
    end

    it "allows write tools only with write scope and live-trading flags" do
      policy = described_class.new(allow_writes: true, allow_live_trading: true, scopes: %i[read_only intent_only write])

      expect(policy.authorize!(tool)).to be(true)
    end
  end
end
