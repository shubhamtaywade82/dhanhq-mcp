# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Options::Selector do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client, meta: { spot_price: 21_000 }) }
  let(:tool) { described_class.new(context) }
  let(:instrument) { double("instrument") }

  let(:base_args) do
    {
      "exchange_segment" => "IDX_I",
      "symbol" => "NIFTY",
      "expiry" => "2024-01-25",
      "direction" => "BULLISH",
      "spot_price" => 21_000,
    }
  end

  let(:sample_chain) do
    [
      double(strike: 20_900, option_type: "CE", ltp: 150, security_id: "SEC001"),
      double(strike: 20_950, option_type: "CE", ltp: 125, security_id: "SEC002"),
      double(strike: 21_000, option_type: "CE", ltp: 100, security_id: "SEC003"),
      double(strike: 21_050, option_type: "CE", ltp: 80, security_id: "SEC004"),
      double(strike: 21_100, option_type: "CE", ltp: 60, security_id: "SEC005"),
      double(strike: 20_900, option_type: "PE", ltp: 50, security_id: "SEC006"),
      double(strike: 21_000, option_type: "PE", ltp: 100, security_id: "SEC007"),
    ]
  end

  before do
    allow(DhanHQ::Models::Instrument).to receive(:find)
      .with("IDX_I", "NIFTY")
      .and_return(instrument)
    allow(instrument).to receive(:option_chain)
      .with(expiry: "2024-01-25")
      .and_return(sample_chain)
  end

  describe "#call" do
    context "with BULLISH direction" do
      it "selects CE strikes ranked by distance from spot" do
        result = tool.call(base_args)

        expect(result.length).to be <= 3
        expect(result.first[:option_type]).to eq("CE")
        expect(result.first[:strike]).to eq(21_000)
      end

      it "excludes PE strikes" do
        result = tool.call(base_args)

        option_types = result.map { |opt| opt[:option_type] }
        expect(option_types).to all(eq("CE"))
      end
    end

    context "with BEARISH direction" do
      it "selects PE strikes" do
        args = base_args.merge("direction" => "BEARISH")

        result = tool.call(args)

        option_types = result.map { |opt| opt[:option_type] }
        expect(option_types).to all(eq("PE"))
      end
    end

    context "with premium filters" do
      it "filters by min_premium" do
        args = base_args.merge("min_premium" => 100)

        result = tool.call(args)

        premiums = result.map { |opt| opt[:ltp] }
        expect(premiums).to all(be >= 100)
      end

      it "filters by max_premium" do
        args = base_args.merge("max_premium" => 100)

        result = tool.call(args)

        premiums = result.map { |opt| opt[:ltp] }
        expect(premiums).to all(be <= 100)
      end
    end

    context "with distance filter" do
      it "filters strikes within max_distance_pct" do
        args = base_args.merge("max_distance_pct" => 0.5)

        result = tool.call(args)

        strikes = result.map { |opt| opt[:strike] }
        strikes.each do |strike|
          distance_pct = ((strike - 21_000).abs.to_f / 21_000) * 100
          expect(distance_pct).to be <= 0.5
        end
      end
    end

    context "with default parameters" do
      it "uses default min_premium of 50" do
        allow(instrument).to receive(:option_chain).and_return([
                                                                 double(strike: 21_000, option_type: "CE", ltp: 30, security_id: "SEC001"),
                                                                 double(strike: 21_100, option_type: "CE", ltp: 100, security_id: "SEC002"),
                                                               ])

        result = tool.call(base_args)

        expect(result.length).to eq(1)
        expect(result.first[:ltp]).to eq(100)
      end

      it "uses default max_premium of 300" do
        allow(instrument).to receive(:option_chain).and_return([
                                                                 double(strike: 21_000, option_type: "CE", ltp: 350, security_id: "SEC001"),
                                                                 double(strike: 21_100, option_type: "CE", ltp: 200, security_id: "SEC002"),
                                                               ])

        result = tool.call(base_args)

        expect(result.length).to eq(1)
        expect(result.first[:ltp]).to eq(200)
      end
    end

    it "returns top 3 ranked strikes" do
      allow(instrument).to receive(:option_chain).and_return([
                                                               double(strike: 20_800, option_type: "CE", ltp: 200, security_id: "SEC001"),
                                                               double(strike: 20_900, option_type: "CE", ltp: 180, security_id: "SEC002"),
                                                               double(strike: 21_000, option_type: "CE", ltp: 150, security_id: "SEC003"),
                                                               double(strike: 21_100, option_type: "CE", ltp: 120, security_id: "SEC004"),
                                                               double(strike: 21_200, option_type: "CE", ltp: 100, security_id: "SEC005"),
                                                             ])

      result = tool.call(base_args)

      expect(result.length).to eq(3)
      expect(result[0][:strike]).to eq(21_000)
      expect(result[1][:strike]).to eq(20_900)
      expect(result[2][:strike]).to eq(21_100)
    end

    it "includes required fields in response" do
      result = tool.call(base_args)

      expect(result.first).to include(:security_id, :strike, :option_type, :ltp, :distance_from_spot)
    end
  end
end
