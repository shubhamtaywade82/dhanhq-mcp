# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Instrument do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:tool) { described_class.new(context) }
  let(:instrument) { double("instrument") }
  let(:args) { { "exchange_segment" => "NSE_EQ", "symbol" => "TCS" } }

  before do
    allow(DhanHQ::Models::Instrument).to receive(:find)
      .with("NSE_EQ", "TCS")
      .and_return(instrument)
  end

  describe "#find" do
    it "returns complete instrument information" do
      allow(instrument).to receive_messages(
        security_id: "11536",
        symbol_name: "TCS",
        display_name: "Tata Consultancy Services Ltd",
        underlying_symbol: "TCS",
        exchange_segment: "NSE_EQ",
        segment: "E",
        instrument: "EQUITY",
        instrument_type: "EQUITY",
        expiry_flag: "N"
      )

      result = tool.find(args)

      expect(result[:security_id]).to eq("11536")
      expect(result[:symbol]).to eq("TCS")
      expect(result[:display_name]).to eq("Tata Consultancy Services Ltd")
      expect(result[:underlying_symbol]).to eq("TCS")
      expect(result[:exchange_segment]).to eq("NSE_EQ")
      expect(result[:segment]).to eq("E")
      expect(result[:instrument]).to eq("EQUITY")
      expect(result[:instrument_type]).to eq("EQUITY")
      expect(result[:expiry_flag]).to eq("N")
    end
  end

  describe "#info" do
    before do
      allow(instrument).to receive_messages(isin: "INE123A01012", buy_sell_indicator: "A", bracket_flag: "Y", cover_flag: "Y", asm_gsm_flag: "N", mtf_leverage: 5, buy_co_min_margin_per: 10.5, sell_co_min_margin_per: 20.0)
    end

    it "returns trading permissions and risk metadata" do
      result = tool.info(args)

      expect(result[:isin]).to eq("INE123A01012")
      expect(result[:trading_allowed]).to be(true)
      expect(result[:bracket_supported]).to be(true)
      expect(result[:cover_supported]).to be(true)
      expect(result[:asm_gsm_status]).to eq("NONE")
    end

    context "when trading is not allowed" do
      it "returns false for trading_allowed" do
        allow(instrument).to receive(:buy_sell_indicator).and_return("D")

        result = tool.info(args)

        expect(result[:trading_allowed]).to be(false)
      end
    end

    context "when ASM/GSM is active" do
      it "returns category name" do
        allow(instrument).to receive_messages(asm_gsm_flag: "Y", asm_gsm_category: "STAGE1")

        result = tool.info(args)

        expect(result[:asm_gsm_status]).to eq("STAGE1")
      end
    end
  end

  describe "#ltp" do
    it "delegates to instrument" do
      ltp_data = { ltp: 3500.50, volume: 1_000_000 }
      allow(instrument).to receive(:ltp).and_return(ltp_data)

      result = tool.ltp(args)

      expect(result).to eq(ltp_data)
    end
  end

  describe "#quote" do
    it "delegates to instrument" do
      quote_data = { bid: 3500, ask: 3501, depth: {} }
      allow(instrument).to receive(:quote).and_return(quote_data)

      result = tool.quote(args)

      expect(result).to eq(quote_data)
    end
  end

  describe "#ohlc" do
    it "delegates to instrument" do
      ohlc_data = { open: 3450, high: 3520, low: 3440, close: 3500 }
      allow(instrument).to receive(:ohlc).and_return(ohlc_data)

      result = tool.ohlc(args)

      expect(result).to eq(ohlc_data)
    end
  end

  describe "#daily" do
    it "fetches daily historical candles" do
      args_with_dates = args.merge("from" => "2024-01-01", "to" => "2024-01-31")
      daily_data = [{ date: "2024-01-01", close: 3500 }]
      allow(instrument).to receive(:daily)
        .with(from_date: "2024-01-01", to_date: "2024-01-31")
        .and_return(daily_data)

      result = tool.daily(args_with_dates)

      expect(result).to eq(daily_data)
    end
  end

  describe "#intraday" do
    it "fetches intraday candles" do
      args_with_interval = args.merge(
        "from" => "2024-01-15",
        "to" => "2024-01-15",
        "interval" => "15",
      )
      intraday_data = [{ time: "09:15", close: 3500 }]
      allow(instrument).to receive(:intraday)
        .with(from_date: "2024-01-15", to_date: "2024-01-15", interval: "15")
        .and_return(intraday_data)

      result = tool.intraday(args_with_interval)

      expect(result).to eq(intraday_data)
    end
  end
end
