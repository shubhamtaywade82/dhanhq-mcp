# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::SuperOrders do
  let(:client) { double("client") }
  let(:market_time) { Time.new(2024, 1, 2, 10, 0, 0, "+05:30") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client, meta: { now: market_time }) }
  let(:tool) { described_class.new(context) }
  let(:instrument) { FakeInstrument.build(security_id: "11536", exchange_segment: "NSE_EQ") }

  let(:place_args) do
    {
      "transaction_type" => "BUY",
      "exchange_segment" => "NSE_EQ",
      "product_type" => "INTRADAY",
      "order_type" => "LIMIT",
      "security_id" => "11536",
      "quantity" => 5,
      "price" => 1400.0,
      "target_price" => 1450.0,
      "stop_loss_price" => 1370.0,
      "trailing_jump" => 5,
    }
  end

  let(:super_order) do
    double(
      "super_order",
      dhan_client_id: nil,
      order_id: "1",
      correlation_id: nil,
      order_status: "PENDING",
      transaction_type: "BUY",
      exchange_segment: "NSE_EQ",
      product_type: "INTRADAY",
      order_type: "LIMIT",
      validity: "DAY",
      trading_symbol: "INFY",
      security_id: "11536",
      quantity: 5,
      remaining_quantity: 5,
      ltp: nil,
      price: 1400.0,
      after_market_order: false,
      leg_name: nil,
      exchange_order_id: nil,
      create_time: nil,
      update_time: nil,
      exchange_time: nil,
      oms_error_description: nil,
      average_traded_price: nil,
      filled_qty: 0,
      leg_details: nil,
      target_price: 1450.0,
      stop_loss_price: 1370.0,
      trailing_jump: 5,
    )
  end

  before do
    allow(DhanHQ::Models::Instrument).to receive(:by_segment).with("NSE_EQ").and_return([instrument])
  end

  describe "#place" do
    it "runs the risk guard before creating the super order" do
      allow(DhanHQ::Models::SuperOrder).to receive(:create).with(place_args).and_return(super_order)

      result = tool.place(place_args)

      expect(result[:order_id]).to eq("1")
      expect(DhanHQ::Models::SuperOrder).to have_received(:create).with(place_args)
    end

    it "never calls the broker when the risk guard rejects the order" do
      allow(DhanHQ::Models::SuperOrder).to receive(:create)
      args = place_args.merge("quantity" => 0)

      expect { tool.place(args) }.to raise_error(Dhanhq::Mcp::Errors::RiskViolation)
      expect(DhanHQ::Models::SuperOrder).not_to have_received(:create)
    end

    it "raises RiskViolation for quantities outside the F&O lot size" do
      fno_instrument = FakeInstrument.build(security_id: "49081", exchange_segment: "NSE_FNO", lot_size: 75)
      allow(DhanHQ::Models::Instrument).to receive(:by_segment).with("NSE_FNO").and_return([fno_instrument])
      args = place_args.merge("exchange_segment" => "NSE_FNO", "security_id" => "49081", "quantity" => 80)

      expect { tool.place(args) }.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, /lot size/)
    end
  end

  describe "#modify" do
    it "requires order_id" do
      expect(tool.modify({})).to eq(error: "order_id is required")
    end

    it "runs the modification risk guard before looking up the order" do
      allow(DhanHQ::Models::SuperOrder).to receive(:all)

      expect do
        tool.modify("order_id" => "1", "quantity" => 0)
      end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, /Quantity must be > 0/)
      expect(DhanHQ::Models::SuperOrder).not_to have_received(:all)
    end

    it "modifies the super order when found" do
      allow(DhanHQ::Models::SuperOrder).to receive(:all).and_return([super_order])
      allow(super_order).to receive(:modify).with({ "price" => 1410.0 }).and_return(true)

      result = tool.modify("order_id" => "1", "price" => 1410.0)

      expect(result).to eq(success: true, order_id: "1")
    end
  end

  describe "#cancel_leg" do
    it "cancels a leg when the order is found" do
      allow(DhanHQ::Models::SuperOrder).to receive(:all).and_return([super_order])
      allow(super_order).to receive(:cancel).with("TARGET_LEG").and_return(true)

      result = tool.cancel_leg("order_id" => "1", "leg_name" => "TARGET_LEG")

      expect(result).to eq(success: true, order_id: "1", leg_name: "TARGET_LEG", status: "CANCELLED")
    end
  end
end
