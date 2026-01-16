# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Base do
  describe "#initialize" do
    let(:client) { double("client") }
    let(:context) { Dhanhq::Mcp::Context.new(client: client) }

    it "stores context" do
      tool = described_class.new(context)

      expect(tool.context).to eq(context)
    end

    it "provides access to context attributes" do
      tool = described_class.new(context)

      expect(tool.context.client).to eq(client)
    end
  end
end
