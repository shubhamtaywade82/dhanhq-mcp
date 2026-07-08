# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::OrdersExecution do
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
      "validity" => "DAY",
      "security_id" => "11536",
      "quantity" => 5,
      "price" => 1400.0,
    }
  end

  let(:order) do
    double(
      "order",
      order_id: "1",
      order_status: "PENDING",
      correlation_id: nil,
      transaction_type: "BUY",
      exchange_segment: "NSE_EQ",
      product_type: "INTRADAY",
      order_type: "LIMIT",
      validity: "DAY",
      trading_symbol: "INFY",
      security_id: "11536",
      quantity: 5,
      disclosed_quantity: nil,
      price: 1400.0,
      trigger_price: nil,
      after_market_order: false,
      bo_profit_value: nil,
      bo_stop_loss_value: nil,
      leg_name: nil,
      create_time: nil,
      update_time: nil,
      exchange_time: nil,
      drv_expiry_date: nil,
      drv_option_type: nil,
      drv_strike_price: nil,
      oms_error_code: nil,
      oms_error_description: nil,
      algo_id: nil,
      remaining_quantity: 5,
      average_traded_price: nil,
      filled_qty: 0,
    )
  end

  before do
    allow(DhanHQ::Models::Instrument).to receive(:by_segment).with("NSE_EQ").and_return([instrument])
  end

  describe "#place" do
    it "runs the risk guard before placing the order" do
      allow(DhanHQ::Models::Order).to receive(:place).with(place_args).and_return(order)

      result = tool.place(place_args)

      expect(result[:order_id]).to eq("1")
      expect(DhanHQ::Models::Order).to have_received(:place).with(place_args)
    end

    it "raises RiskViolation when order_type is omitted without a price" do
      args = place_args.except("order_type", "price")

      expect { tool.place(args) }.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, /require a positive price/)
    end

    it "raises RiskViolation for quantities outside the F&O lot size" do
      fno_instrument = FakeInstrument.build(security_id: "49081", exchange_segment: "NSE_FNO", lot_size: 75)
      allow(DhanHQ::Models::Instrument).to receive(:by_segment).with("NSE_FNO").and_return([fno_instrument])
      args = place_args.merge("exchange_segment" => "NSE_FNO", "security_id" => "49081", "quantity" => 80)

      expect { tool.place(args) }.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, /lot size/)
    end

    it "never calls the broker when the risk guard rejects the order" do
      allow(DhanHQ::Models::Order).to receive(:place)
      args = place_args.merge("quantity" => 0)

      expect { tool.place(args) }.to raise_error(Dhanhq::Mcp::Errors::RiskViolation)
      expect(DhanHQ::Models::Order).not_to have_received(:place)
    end

    it "returns an error hash when placement fails" do
      allow(DhanHQ::Models::Order).to receive(:place).and_return(nil)

      expect(tool.place(place_args)).to eq(error: "Order placement failed")
    end
  end

  describe "#modify" do
    it "requires order_id" do
      expect(tool.modify({})).to eq(error: "order_id is required")
    end

    it "runs the modification risk guard before finding the order" do
      allow(DhanHQ::Models::Order).to receive(:find)

      expect do
        tool.modify("order_id" => "1", "quantity" => 0)
      end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, /Quantity must be > 0/)
      expect(DhanHQ::Models::Order).not_to have_received(:find)
    end

    it "modifies the order when found" do
      allow(DhanHQ::Models::Order).to receive(:find).with("1").and_return(order)
      allow(order).to receive(:modify).with({ "price" => 1410.0 }).and_return(order)

      result = tool.modify("order_id" => "1", "price" => 1410.0)

      expect(result[:order_id]).to eq("1")
    end
  end

  describe "#cancel" do
    it "cancels the order when found" do
      allow(DhanHQ::Models::Order).to receive(:find).with("1").and_return(order)
      allow(order).to receive(:cancel).and_return(true)

      result = tool.cancel("order_id" => "1")

      expect(result).to eq(success: true, order_id: "1", status: "CANCELLED")
    end
  end
end
