# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Orders do
  let(:client) { double("client") }
  let(:market_time) { Time.new(2024, 1, 2, 10, 0, 0, "+05:30") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client, meta: { now: market_time }) }
  let(:tool) { described_class.new(context) }
  let(:instrument) { double("instrument") }

  let(:valid_args) do
    {
      "exchange_segment" => "NSE_EQ",
      "symbol" => "INFY",
      "transaction_type" => "BUY",
      "quantity" => 10,
      "order_type" => "MARKET",
      "product_type" => "INTRADAY",
      "stop_loss" => 1400,
      "target" => 1500,
    }
  end

  before do
    allow(DhanHQ::Models::Instrument).to receive(:find)
      .with("NSE_EQ", "INFY")
      .and_return(instrument)
    allow(instrument).to receive_messages(
      symbol_name: "INFY",
      exchange_segment: "NSE_EQ",
      buy_sell_indicator: "A",
      asm_gsm_flag: "N",
      asm_gsm_category: "ASM",
      instrument_type: "EQUITY",
    )
  end

  describe "#prepare" do
    context "with valid arguments" do
      it "builds trade intent" do
        result = tool.prepare(valid_args)

        expect(result[:trade_type]).to eq("EQUITY_FUTURES")
        expect(result[:instrument]).to eq("INFY (NSE_EQ)")
        expect(result[:transaction_type]).to eq("BUY")
        expect(result[:quantity]).to eq(10)
        expect(result[:stop_loss]).to eq(1400)
        expect(result[:target]).to eq(1500)
      end

      it "includes confirmation note" do
        result = tool.prepare(valid_args)

        expect(result[:note]).to eq("Prepared trade intent. Await human confirmation.")
      end
    end

    context "when trading is disabled" do
      it "raises RiskViolation" do
        allow(instrument).to receive(:buy_sell_indicator).and_return("D")

        expect do
          tool.prepare(valid_args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Trading disabled for instrument")
      end
    end

    context "when ASM/GSM is restricted" do
      it "raises RiskViolation" do
        allow(instrument).to receive(:asm_gsm_flag).and_return("Y")
        allow(instrument).to receive(:asm_gsm_category).and_return("GSM")

        expect do
          tool.prepare(valid_args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "ASM/GSM restricted instrument (GSM)")
      end
    end

    context "with invalid quantity" do
      it "raises RiskViolation for zero quantity" do
        args = valid_args.merge("quantity" => 0)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Quantity must be > 0")
      end

      it "raises RiskViolation for negative quantity" do
        args = valid_args.merge("quantity" => -5)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Quantity must be > 0")
      end
    end

    context "when quantity exceeds limit" do
      it "raises RiskViolation" do
        args = valid_args.merge("quantity" => 11)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Quantity exceeds limit")
      end
    end

    context "when notional exceeds limit" do
      it "raises RiskViolation" do
        args = valid_args.merge("price" => 10_001)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Notional exceeds limit")
      end
    end

    context "when order type is invalid" do
      it "raises RiskViolation" do
        args = valid_args.merge("order_type" => "STOP")

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid order type")
      end
    end

    context "without stop loss or target" do
      it "builds intent successfully without risk params" do
        args = valid_args.except("stop_loss", "target")

        result = tool.prepare(args)

        expect(result[:trade_type]).to eq("EQUITY_FUTURES")
      end
    end
  end
end
