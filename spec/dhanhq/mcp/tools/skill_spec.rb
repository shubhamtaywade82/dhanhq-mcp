# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Skill do
  let(:context) { Dhanhq::Mcp::Context.new(client: double("client")) }
  let(:tool) { described_class.new(context) }

  before do
    DhanHQ::Skills::Registry.clear!
    DhanHQ::Skills::Registry.load_builtins
  end

  describe "#call" do
    it "raises InvalidArguments when name is missing" do
      expect { tool.call({}) }.to raise_error(Dhanhq::Mcp::Errors::InvalidArguments, /name/)
    end

    it "raises InvalidArguments when name is empty" do
      expect { tool.call("name" => "") }.to raise_error(Dhanhq::Mcp::Errors::InvalidArguments, /name/)
    end

    it "raises InvalidArguments for unknown skill" do
      expect do
        tool.call("name" => "nonexistent_skill")
      end.to raise_error(Dhanhq::Mcp::Errors::InvalidArguments, /Unknown skill/)
    end

    it "raises InvalidArguments when required params are missing" do
      expect do
        tool.call("name" => "buy_atm_call", "params" => {})
      end.to raise_error(Dhanhq::Mcp::Errors::InvalidArguments, /symbol/)
    end

    it "returns skill list from skill.list handler" do
      list = DhanHQ::Skills::Registry.list
      expect(list).to be_an(Array)
      expect(list.length).to be >= 5
      expect(list.map { |s| s[:name] }).to include("buy_atm_call", "square_off_all", "iron_condor")
    end

    it "includes params and steps in skill metadata" do
      list = DhanHQ::Skills::Registry.list
      buy_atm = list.find { |s| s[:name] == "buy_atm_call" }

      expect(buy_atm[:params]).to include(:symbol, :expiry)
      expect(buy_atm[:steps]).to include(:find_instrument, :get_spot_price, :prepare_intent)
    end
  end
end
