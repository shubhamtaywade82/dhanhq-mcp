# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Portfolio do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:tool) { described_class.new(context) }

  describe "#holdings" do
    it "fetches holdings from DhanHQ Models" do
      holdings_data = [{ symbol: "INFY", quantity: 10 }]
      allow(DhanHQ::Models::Holding).to receive(:all).and_return(holdings_data)

      result = tool.holdings

      expect(result).to eq(holdings_data)
      expect(DhanHQ::Models::Holding).to have_received(:all)
    end
  end

  describe "#positions" do
    it "fetches positions from DhanHQ Models" do
      positions_data = [{ symbol: "NIFTY", quantity: 50 }]
      allow(DhanHQ::Models::Position).to receive(:all).and_return(positions_data)

      result = tool.positions

      expect(result).to eq(positions_data)
      expect(DhanHQ::Models::Position).to have_received(:all)
    end
  end

  describe "#funds" do
    it "fetches funds from DhanHQ Models" do
      funds_data = double("funds", available_balance: 50_000, sod_limit: 70_000)
      allow(DhanHQ::Models::Funds).to receive(:fetch).and_return(funds_data)

      result = tool.funds

      expect(result).to eq(funds_data)
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
