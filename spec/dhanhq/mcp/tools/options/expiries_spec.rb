# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Options::Expiries do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:tool) { described_class.new(context) }
  let(:instrument) { double("instrument") }
  let(:args) { { "exchange_segment" => "IDX_I", "symbol" => "NIFTY" } }

  before do
    allow(DhanHQ::Models::Instrument).to receive(:find)
      .with("IDX_I", "NIFTY")
      .and_return(instrument)
  end

  describe "#call" do
    it "fetches expiry list from instrument" do
      expiries = %w[2024-01-25 2024-02-01 2024-02-08]
      allow(instrument).to receive(:expiry_list).and_return(expiries)

      result = tool.call(args)

      expect(result).to eq(expiries)
      expect(instrument).to have_received(:expiry_list)
    end

    it "returns empty array when no expiries available" do
      allow(instrument).to receive(:expiry_list).and_return([])

      result = tool.call(args)

      expect(result).to eq([])
    end
  end
end
