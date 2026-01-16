# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Orders do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
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
    allow(instrument).to receive_messages(symbol_name: "INFY", exchange_segment: "NSE_EQ", buy_sell_indicator: "A", asm_gsm_flag: "N", instrument_type: "EQUITY")
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

        expect do
          tool.prepare(valid_args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "ASM/GSM restricted")
      end
    end

    context "when instrument is INDEX type" do
      it "raises RiskViolation" do
        allow(instrument).to receive(:instrument_type).and_return("INDEX")

        expect do
          tool.prepare(valid_args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Use option.prepare for index options")
      end
    end

    context "with invalid quantity" do
      it "raises RiskViolation for zero quantity" do
        args = valid_args.merge("quantity" => 0)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid quantity")
      end

      it "raises RiskViolation for negative quantity" do
        args = valid_args.merge("quantity" => -5)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid quantity")
      end
    end

    context "with invalid stop loss" do
      it "raises RiskViolation" do
        args = valid_args.merge("stop_loss" => -100)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid stop loss")
      end
    end

    context "with invalid target" do
      it "raises RiskViolation" do
        args = valid_args.merge("target" => -100)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid target")
      end
    end

    context "with bad risk-reward ratio for BUY" do
      it "raises RiskViolation when target is below stop loss" do
        args = valid_args.merge("transaction_type" => "BUY", "stop_loss" => 1500, "target" => 1400)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Bad risk-reward ratio")
      end
    end

    context "with bad risk-reward ratio for SELL" do
      it "raises RiskViolation when stop loss is below target" do
        args = valid_args.merge("transaction_type" => "SELL", "stop_loss" => 1400, "target" => 1500)

        expect do
          tool.prepare(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Bad risk-reward ratio")
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
