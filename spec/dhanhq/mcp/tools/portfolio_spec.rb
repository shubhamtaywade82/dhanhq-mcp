# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Portfolio do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:tool) { described_class.new(context) }

  describe "#holdings" do
    it "fetches holdings from DhanHQ Models and serializes to hashes" do
      holding_obj = double("holding", to_h: { symbol: "INFY", quantity: 10 })
      allow(DhanHQ::Models::Holding).to receive(:all).and_return([holding_obj])

      result = tool.holdings

      expect(result).to eq([{ symbol: "INFY", quantity: 10 }])
      expect(result.first).to be_a(Hash)
      expect(DhanHQ::Models::Holding).to have_received(:all)
    end

    it "handles already serialized hash responses" do
      holdings_data = [{ symbol: "INFY", quantity: 10 }]
      allow(DhanHQ::Models::Holding).to receive(:all).and_return(holdings_data)

      result = tool.holdings

      expect(result).to eq(holdings_data)
    end
  end

  describe "#positions" do
    it "fetches positions from DhanHQ Models and serializes to hashes" do
      position_obj = double("position", attributes: { symbol: "NIFTY", quantity: 50 })
      allow(DhanHQ::Models::Position).to receive(:all).and_return([position_obj])

      result = tool.positions

      expect(result).to eq([{ symbol: "NIFTY", quantity: 50 }])
      expect(result.first).to be_a(Hash)
      expect(DhanHQ::Models::Position).to have_received(:all)
    end
  end

  describe "#funds" do
    it "fetches funds from DhanHQ Models and serializes to hash" do
      funds_obj = double("funds",
                         attributes: { available_balance: 50_000, sod_limit: 70_000 },
                         available_balance: 50_000,
                         sod_limit: 70_000)
      allow(DhanHQ::Models::Funds).to receive(:fetch).and_return(funds_obj)

      result = tool.funds

      expect(result).to eq({ available_balance: 50_000, sod_limit: 70_000 })
      expect(result).to be_a(Hash)
      expect(DhanHQ::Models::Funds).to have_received(:fetch)
    end
  end

  describe "#orders" do
    it "fetches order book from DhanHQ Models" do
      orders_data = [{ order_id: "ORD123", status: "PENDING" }]
      allow(DhanHQ::Models::Order).to receive(:all).and_return(orders_data)

      result = tool.orders

      expect(result).to eq(orders_data)
      expect(DhanHQ::Models::Order).to have_received(:all)
    end
  end

  describe "#trades" do
    it "fetches trade book from DhanHQ Models" do
      trades_data = [{ trade_id: "TRD456", executed_at: "2024-01-15" }]
      allow(DhanHQ::Models::Trade).to receive(:today).and_return(trades_data)

      result = tool.trades

      expect(result).to eq(trades_data)
      expect(DhanHQ::Models::Trade).to have_received(:today)
    end
  end
end
