# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Options::Chain do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:tool) { described_class.new(context) }
  let(:instrument) { double("instrument") }
  let(:args) do
    {
      "exchange_segment" => "IDX_I",
      "symbol" => "NIFTY",
      "expiry" => "2024-01-25",
    }
  end

  before do
    allow(DhanHQ::Models::Instrument).to receive(:find)
      .with("IDX_I", "NIFTY")
      .and_return(instrument)
  end

  describe "#call" do
    it "fetches option chain for given expiry" do
      chain_data = [
        { strike: 21_000, option_type: "CE", ltp: 150 },
        { strike: 21_000, option_type: "PE", ltp: 120 },
      ]
      allow(instrument).to receive(:option_chain)
        .with(expiry: "2024-01-25")
        .and_return(chain_data)

      result = tool.call(args)

      expect(result).to eq(chain_data)
      expect(instrument).to have_received(:option_chain).with(expiry: "2024-01-25")
    end

    it "returns empty array when no options available" do
      allow(instrument).to receive(:option_chain)
        .with(expiry: "2024-01-25")
        .and_return([])

      result = tool.call(args)

      expect(result).to eq([])
    end
  end
end
