# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Router do
  let(:client) { double("client") }
  let(:market_time) { Time.new(2024, 1, 2, 10, 0, 0, "+05:30") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client, meta: { now: market_time }) }

  describe ".call" do
    context "with unknown tool" do
      it "raises UnknownTool error" do
        expect do
          described_class.call("unknown.tool", {}, context)
        end.to raise_error(Dhanhq::Mcp::Errors::UnknownTool, "unknown.tool")
      end
    end

    context "with portfolio tools" do
      it "routes portfolio.holdings" do
        allow(DhanHQ::Models::Holding).to receive(:all).and_return([{ symbol: "RELIANCE" }])

        result = described_class.call("portfolio.holdings", {}, context)

        expect(result).to eq([{ symbol: "RELIANCE" }])
      end

      it "routes portfolio.positions" do
        allow(DhanHQ::Models::Position).to receive(:all).and_return([{ symbol: "NIFTY" }])

        result = described_class.call("portfolio.positions", {}, context)

        expect(result).to eq([{ symbol: "NIFTY" }])
      end

      it "routes portfolio.funds" do
        funds_data = double("funds", available_balance: 10_000)
        allow(DhanHQ::Models::Funds).to receive(:fetch).and_return(funds_data)

        result = described_class.call("portfolio.funds", {}, context)

        expect(result).to eq(funds_data)
      end

      it "routes portfolio.orders" do
        allow(DhanHQ::Models::Order).to receive(:all).and_return([{ order_id: "123" }])

        result = described_class.call("portfolio.orders", {}, context)

        expect(result).to eq([{ order_id: "123" }])
      end

      it "routes portfolio.trades" do
        allow(DhanHQ::Models::Trade).to receive(:today).and_return([{ trade_id: "456" }])

        result = described_class.call("portfolio.trades", {}, context)

        expect(result).to eq([{ trade_id: "456" }])
      end
    end

    context "with instrument tools" do
      let(:instrument) { double("instrument") }
      let(:args) { { "exchange_segment" => "NSE_EQ", "symbol" => "RELIANCE" } }

      before do
        allow(DhanHQ::Models::Instrument).to receive(:find)
          .with("NSE_EQ", "RELIANCE")
          .and_return(instrument)
      end

      it "routes instrument.find" do
        allow(instrument).to receive_messages(
          security_id: "2885",
          symbol_name: "RELIANCE",
          display_name: "Reliance Industries Ltd",
          underlying_symbol: "RELIANCE",
          exchange_segment: "NSE_EQ",
          segment: "E",
          instrument: "EQUITY",
          instrument_type: "EQUITY",
          expiry_flag: "N",
        )

        result = described_class.call("instrument.find", args, context)

        expect(result[:security_id]).to eq("2885")
        expect(result[:symbol]).to eq("RELIANCE")
        expect(result[:exchange_segment]).to eq("NSE_EQ")
      end

      it "routes instrument.ltp" do
        allow(instrument).to receive(:ltp).and_return({ ltp: 2500 })

        result = described_class.call("instrument.ltp", args, context)

        expect(result).to eq({ ltp: 2500 })
      end

      it "routes instrument.quote" do
        allow(instrument).to receive(:quote).and_return({ bid: 2499, ask: 2501 })

        result = described_class.call("instrument.quote", args, context)

        expect(result).to eq({ bid: 2499, ask: 2501 })
      end

      it "routes instrument.ohlc" do
        allow(instrument).to receive(:ohlc).and_return({ open: 2480, high: 2520 })

        result = described_class.call("instrument.ohlc", args, context)

        expect(result).to eq({ open: 2480, high: 2520 })
      end

      it "routes instrument.daily" do
        args_with_dates = args.merge("from" => "2024-01-01", "to" => "2024-01-31")
        allow(instrument).to receive(:daily).with(from_date: "2024-01-01", to_date: "2024-01-31")
                                            .and_return([{ date: "2024-01-01", close: 2500 }])

        result = described_class.call("instrument.daily", args_with_dates, context)

        expect(result).to eq([{ date: "2024-01-01", close: 2500 }])
      end

      it "routes instrument.intraday" do
        args_with_interval = args.merge("from" => "2024-01-01", "to" => "2024-01-01", "interval" => "5")
        allow(instrument).to receive(:intraday)
          .with(from_date: "2024-01-01", to_date: "2024-01-01", interval: "5")
          .and_return([{ time: "09:15", close: 2500 }])

        result = described_class.call("instrument.intraday", args_with_interval, context)

        expect(result).to eq([{ time: "09:15", close: 2500 }])
      end
    end

    context "with option tools" do
      let(:instrument) { double("instrument") }
      let(:args) { { "exchange_segment" => "IDX_I", "symbol" => "NIFTY" } }

      before do
        allow(DhanHQ::Models::Instrument).to receive(:find)
          .with("IDX_I", "NIFTY")
          .and_return(instrument)
      end

      it "routes option.expiries" do
        allow(instrument).to receive(:expiry_list).and_return(%w[2024-01-25 2024-02-01])

        result = described_class.call("option.expiries", args, context)

        expect(result).to eq(%w[2024-01-25 2024-02-01])
      end

      it "routes option.chain" do
        args_with_expiry = args.merge("expiry" => "2024-01-25")
        allow(instrument).to receive(:option_chain).with(expiry: "2024-01-25")
                                                   .and_return([{ strike: 21_000 }])

        result = described_class.call("option.chain", args_with_expiry, context)

        expect(result).to eq([{ strike: 21_000 }])
      end

      it "routes option.select" do
        option = double(strike: 21_000, option_type: "CE", ltp: 100, security_id: "SEC123")
        context_with_meta = Dhanhq::Mcp::Context.new(client: client, meta: { spot_price: 21_000 })
        args_with_selection = args.merge(
          "expiry" => "2024-01-25",
          "direction" => "BULLISH",
          "spot_price" => 21_000,
        )
        allow(instrument).to receive(:option_chain).and_return([option])

        result = described_class.call("option.select", args_with_selection, context_with_meta)

        expect(result).to be_an(Array)
      end

      it "routes option.prepare" do
        args_with_trade = args.merge(
          "security_id" => "SEC123",
          "option_type" => "CE",
          "strike" => 21_000,
          "expiry" => "2024-01-25",
          "quantity" => 10,
          "stop_loss" => 80,
          "target" => 150,
        )
        allow(instrument).to receive_messages(symbol_name: "NIFTY", buy_sell_indicator: "A", asm_gsm_flag: "N", instrument_type: "INDEX")

        result = described_class.call("option.prepare", args_with_trade, context)

        expect(result[:trade_type]).to eq("OPTIONS_BUY")
      end
    end

    context "with orders tools" do
      let(:instrument) { double("instrument") }
      let(:args) do
        {
          "exchange_segment" => "NSE_EQ",
          "symbol" => "INFY",
          "transaction_type" => "BUY",
          "quantity" => 10,
          "order_type" => "MARKET",
          "product_type" => "INTRADAY",
        }
      end

      before do
        allow(DhanHQ::Models::Instrument).to receive(:find)
          .with("NSE_EQ", "INFY")
          .and_return(instrument)
        allow(instrument).to receive_messages(symbol_name: "INFY", exchange_segment: "NSE_EQ", buy_sell_indicator: "A", asm_gsm_flag: "N", instrument_type: "EQUITY")
      end

      it "routes orders.prepare" do
        result = described_class.call("orders.prepare", args, context)

        expect(result[:trade_type]).to eq("EQUITY_FUTURES")
      end
    end
  end
end
