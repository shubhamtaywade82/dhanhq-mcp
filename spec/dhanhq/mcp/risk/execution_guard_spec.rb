# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Risk::ExecutionGuard do
  let(:market_time) { Time.new(2024, 1, 2, 10, 0, 0, "+05:30") }
  let(:instrument) { FakeInstrument.build(security_id: "11536", exchange_segment: "NSE_EQ") }

  let(:base_args) do
    {
      "transaction_type" => "BUY",
      "exchange_segment" => "NSE_EQ",
      "product_type" => "INTRADAY",
      "order_type" => "LIMIT",
      "validity" => "DAY",
      "security_id" => "11536",
      "quantity" => 5,
      "price" => 100.0,
    }
  end

  before do
    allow(DhanHQ::Models::Instrument).to receive(:by_segment)
      .with("NSE_EQ").and_return([instrument])
  end

  describe ".for_placement!" do
    it "passes valid LIMIT orders through unchanged" do
      result = described_class.for_placement!(base_args, now: market_time)

      expect(result["order_type"]).to eq("LIMIT")
      expect(result["quantity"]).to eq(5)
    end

    it "defaults order_type to LIMIT when omitted" do
      args = base_args.except("order_type")

      result = described_class.for_placement!(args, now: market_time)

      expect(result["order_type"]).to eq("LIMIT")
    end

    it "does not mutate the caller's args when applying the default" do
      args = base_args.except("order_type")

      described_class.for_placement!(args, now: market_time)

      expect(args).not_to have_key("order_type")
    end

    it "rejects LIMIT orders without a price" do
      args = base_args.except("price")

      expect do
        described_class.for_placement!(args, now: market_time)
      end.to raise_error(DhanHQ::RiskViolation, /require a positive price/)
    end

    it "allows MARKET orders without a price" do
      args = base_args.merge("order_type" => "MARKET").except("price")

      expect(described_class.for_placement!(args, now: market_time)["order_type"]).to eq("MARKET")
    end

    it "rejects STOP_LOSS orders without a trigger price" do
      args = base_args.merge("order_type" => "STOP_LOSS")

      expect do
        described_class.for_placement!(args, now: market_time)
      end.to raise_error(DhanHQ::RiskViolation, /trigger_price/)
    end

    it "accepts STOP_LOSS orders with price and trigger price" do
      args = base_args.merge("order_type" => "STOP_LOSS", "trigger_price" => 99.5)

      expect(described_class.for_placement!(args, now: market_time)["order_type"]).to eq("STOP_LOSS")
    end

    it "rejects invalid order types" do
      args = base_args.merge("order_type" => "ICEBERG")

      expect do
        described_class.for_placement!(args, now: market_time)
      end.to raise_error(DhanHQ::RiskViolation, /Invalid order type/)
    end

    it "rejects non-positive quantity" do
      args = base_args.merge("quantity" => 0)

      expect do
        described_class.for_placement!(args, now: market_time)
      end.to raise_error(DhanHQ::RiskViolation, /Quantity must be > 0/)
    end

    it "rejects orders outside market hours" do
      after_close = Time.new(2024, 1, 2, 16, 0, 0, "+05:30")

      expect do
        described_class.for_placement!(base_args, now: after_close)
      end.to raise_error(DhanHQ::RiskViolation, /Market is closed/)
    end

    it "allows AMO orders outside market hours" do
      after_close = Time.new(2024, 1, 2, 16, 0, 0, "+05:30")
      args = base_args.merge("after_market_order" => true)

      expect(described_class.for_placement!(args, now: after_close)["quantity"]).to eq(5)
    end

    it "blocks instruments where trading is disabled" do
      blocked = FakeInstrument.build(security_id: "11536", buy_sell_indicator: "D")
      allow(DhanHQ::Models::Instrument).to receive(:by_segment).and_return([blocked])

      expect do
        described_class.for_placement!(base_args, now: market_time)
      end.to raise_error(DhanHQ::RiskViolation, /Trading disabled/)
    end

    it "blocks ASM/GSM restricted instruments" do
      restricted = FakeInstrument.build(security_id: "11536", asm_gsm_flag: "Y", asm_gsm_category: "GSM-II")
      allow(DhanHQ::Models::Instrument).to receive(:by_segment).and_return([restricted])

      expect do
        described_class.for_placement!(base_args, now: market_time)
      end.to raise_error(DhanHQ::RiskViolation, %r{ASM/GSM})
    end

    it "skips instrument-level checks when the master is unavailable" do
      allow(DhanHQ::Models::Instrument).to receive(:by_segment).and_raise(StandardError, "download failed")

      expect(described_class.for_placement!(base_args, now: market_time)["quantity"]).to eq(5)
    end

    context "with F&O lot sizes" do
      let(:fno_instrument) do
        FakeInstrument.build(security_id: "49081", exchange_segment: "NSE_FNO", lot_size: 75)
      end

      let(:fno_args) do
        base_args.merge("exchange_segment" => "NSE_FNO", "security_id" => "49081", "product_type" => "MARGIN")
      end

      before do
        allow(DhanHQ::Models::Instrument).to receive(:by_segment)
          .with("NSE_FNO").and_return([fno_instrument])
      end

      it "rejects quantities that are not lot-size multiples" do
        args = fno_args.merge("quantity" => 80)

        expect do
          described_class.for_placement!(args, now: market_time)
        end.to raise_error(DhanHQ::RiskViolation, /not a multiple of lot size 75/)
      end

      it "accepts quantities that are lot-size multiples" do
        args = fno_args.merge("quantity" => 150)

        expect(described_class.for_placement!(args, now: market_time)["quantity"]).to eq(150)
      end
    end

    context "with environment caps" do
      around do |example|
        ENV["DHANHQ_MCP_MAX_QUANTITY"] = "5"
        ENV["DHANHQ_MCP_MAX_NOTIONAL"] = "10000"
        example.run
      ensure
        ENV.delete("DHANHQ_MCP_MAX_QUANTITY")
        ENV.delete("DHANHQ_MCP_MAX_NOTIONAL")
      end

      it "rejects quantities above DHANHQ_MCP_MAX_QUANTITY" do
        args = base_args.merge("quantity" => 6)

        expect do
          described_class.for_placement!(args, now: market_time)
        end.to raise_error(DhanHQ::RiskViolation, /DHANHQ_MCP_MAX_QUANTITY/)
      end

      it "rejects notionals above DHANHQ_MCP_MAX_NOTIONAL" do
        args = base_args.merge("quantity" => 5, "price" => 5000.0)

        expect do
          described_class.for_placement!(args, now: market_time)
        end.to raise_error(DhanHQ::RiskViolation, /DHANHQ_MCP_MAX_NOTIONAL/)
      end

      it "accepts orders within both caps" do
        expect(described_class.for_placement!(base_args, now: market_time)["quantity"]).to eq(5)
      end
    end
  end

  describe ".for_modification!" do
    it "accepts price-only modifications without other fields" do
      args = { "order_id" => "1", "price" => 101.5 }

      expect(described_class.for_modification!(args)).to eq(args)
    end

    it "rejects invalid order types when provided" do
      args = { "order_id" => "1", "order_type" => "ICEBERG" }

      expect do
        described_class.for_modification!(args)
      end.to raise_error(DhanHQ::RiskViolation, /Invalid order type/)
    end

    it "rejects non-positive quantity when provided" do
      args = { "order_id" => "1", "quantity" => 0 }

      expect do
        described_class.for_modification!(args)
      end.to raise_error(DhanHQ::RiskViolation, /Quantity must be > 0/)
    end

    it "rejects LIMIT modifications without a price" do
      args = { "order_id" => "1", "order_type" => "LIMIT" }

      expect do
        described_class.for_modification!(args)
      end.to raise_error(DhanHQ::RiskViolation, /require a positive price/)
    end
  end
end
