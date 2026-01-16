# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Errors do
  describe "error hierarchy" do
    it "defines McpError as base error" do
      expect(described_class::McpError).to be < StandardError
    end

    it "defines UnknownTool error" do
      expect(described_class::UnknownTool).to be < described_class::McpError
    end

    it "defines InvalidArguments error" do
      expect(described_class::InvalidArguments).to be < described_class::McpError
    end

    it "defines RiskViolation error" do
      expect(described_class::RiskViolation).to be < described_class::McpError
    end
  end

  describe "raising errors" do
    it "raises UnknownTool with message" do
      expect do
        raise described_class::UnknownTool, "invalid.tool"
      end.to raise_error(described_class::UnknownTool, "invalid.tool")
    end

    it "raises InvalidArguments with message" do
      expect do
        raise described_class::InvalidArguments, "Missing required argument"
      end.to raise_error(described_class::InvalidArguments, "Missing required argument")
    end

    it "raises RiskViolation with message" do
      expect do
        raise described_class::RiskViolation, "Stop loss required"
      end.to raise_error(described_class::RiskViolation, "Stop loss required")
    end
  end
end
