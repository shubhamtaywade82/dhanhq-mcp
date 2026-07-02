# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::ToolRegistry do
  describe ".tools" do
    it "adds scope, version, and risk metadata to tool specifications" do
      tool = described_class.tools.find { |entry| entry[:name] == "orders.place" }

      expect(tool).to include(scope: :write, version: "1.0.0", risk: "high")
    end
  end

  describe ".fetch" do
    it "raises UnknownTool for missing tools" do
      expect do
        described_class.fetch("missing.tool")
      end.to raise_error(Dhanhq::Mcp::Errors::UnknownTool, "missing.tool")
    end
  end
end
