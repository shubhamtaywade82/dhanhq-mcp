# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Options::Prepare do
  let(:client) { double("client") }
  let(:market_time) { Time.new(2024, 1, 2, 10, 0, 0, "+05:30") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client, meta: { now: market_time }) }
  let(:tool) { described_class.new(context) }
  let(:instrument) { double("instrument") }

  let(:valid_args) do
    {
      "exchange_segment" => "IDX_I",
      "symbol" => "NIFTY",
      "security_id" => "SEC123",
      "option_type" => "CE",
      "strike" => 21_000,
      "expiry" => "2024-01-25",
      "quantity" => 10,
      "stop_loss" => 80,
      "target" => 150,
    }
  end

  before do
    allow(DhanHQ::Models::Instrument).to receive(:find)
      .with("IDX_I", "NIFTY")
      .and_return(instrument)
    allow(instrument).to receive_messages(
      symbol_name: "NIFTY",
      buy_sell_indicator: "A",
      asm_gsm_flag: "N",
      asm_gsm_category: "ASM",
      instrument_type: "INDEX",
    )
  end

  describe "#call" do
    context "with valid arguments" do
      it "builds trade intent" do
        result = tool.call(valid_args)

        expect(result[:trade_type]).to eq("OPTIONS_BUY")
        expect(result[:instrument]).to eq("NIFTY 21000 CE")
        expect(result[:security_id]).to eq("SEC123")
        expect(result[:expiry]).to eq("2024-01-25")
        expect(result[:quantity]).to eq(10)
        expect(result[:stop_loss]).to eq(80)
        expect(result[:target]).to eq(150)
      end

      it "includes confirmation note" do
        result = tool.call(valid_args)

        expect(result[:note]).to eq("Prepared options BUY trade. Await human confirmation.")
      end
    end

    context "when trading is disabled" do
      it "raises RiskViolation" do
        allow(instrument).to receive(:buy_sell_indicator).and_return("D")

        expect do
          tool.call(valid_args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Trading disabled for instrument")
      end
    end

    context "when ASM/GSM is restricted" do
      it "raises RiskViolation" do
        allow(instrument).to receive(:asm_gsm_flag).and_return("Y")
        allow(instrument).to receive(:asm_gsm_category).and_return("GSM")

        expect do
          tool.call(valid_args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "ASM/GSM restricted instrument (GSM)")
      end
    end

    context "when instrument is not INDEX type" do
      it "raises RiskViolation" do
        allow(instrument).to receive(:instrument_type).and_return("EQUITY")

        expect do
          tool.call(valid_args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Options only allowed on index")
      end
    end

    context "without stop loss" do
      it "raises RiskViolation" do
        args = valid_args.except("stop_loss")

        expect do
          tool.call(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Stop loss required")
      end
    end

    context "without target" do
      it "raises RiskViolation" do
        args = valid_args.except("target")

        expect do
          tool.call(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Target required")
      end
    end

    context "with bad risk-reward ratio" do
      it "raises RiskViolation when target is below or equal to stop loss" do
        args = valid_args.merge("stop_loss" => 150, "target" => 100)

        expect do
          tool.call(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid risk-reward")
      end

      it "raises RiskViolation when target equals stop loss" do
        args = valid_args.merge("stop_loss" => 100, "target" => 100)

        expect do
          tool.call(args)
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid risk-reward")
      end
    end

    context "with PE option type" do
      it "builds correct instrument name" do
        args = valid_args.merge("option_type" => "PE")

        result = tool.call(args)

        expect(result[:instrument]).to eq("NIFTY 21000 PE")
      end
    end
  end
end
