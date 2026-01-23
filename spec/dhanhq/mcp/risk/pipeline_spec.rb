# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Risk::Pipeline do
  let(:client) { double("client") }
  let(:market_time) { Time.new(2024, 1, 2, 10, 0, 0, "+05:30") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client, meta: { now: market_time }) }
  let(:instrument) { FakeInstrument.build }
  let(:base_args) { { "quantity" => 1 } }

  describe ".run!" do
    context "with valid equity inputs" do
      it "passes without error" do
        expect do
          described_class.run!(
            context: context,
            args: base_args,
            instrument: instrument,
            type: :equity,
          )
        end.not_to raise_error
      end
    end

    context "when ASM/GSM restriction is active" do
      it "raises RiskViolation" do
        restricted = FakeInstrument.build(asm_gsm_flag: "Y", asm_gsm_category: "ASM")

        expect do
          described_class.run!(
            context: context,
            args: base_args,
            instrument: restricted,
            type: :equity,
          )
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation)
      end
    end

    context "when quantity is zero" do
      it "raises RiskViolation" do
        args = { "quantity" => 0 }

        expect do
          described_class.run!(
            context: context,
            args: args,
            instrument: instrument,
            type: :equity,
          )
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation)
      end
    end

    context "when market is closed" do
      it "raises RiskViolation" do
        closed_context = Dhanhq::Mcp::Context.new(client: client)

        Timecop.freeze(Time.new(2024, 1, 2, 8, 0, 0, "+05:30")) do
          expect do
            described_class.run!(
              context: closed_context,
              args: base_args,
              instrument: instrument,
              type: :equity,
            )
          end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Market is closed")
        end
      end
    end

    context "with options inputs" do
      it "raises RiskViolation when instrument is not an index" do
        non_index = FakeInstrument.build(instrument_type: "EQUITY")

        expect do
          described_class.run!(
            context: context,
            args: base_args.merge("stop_loss" => 80, "target" => 100),
            instrument: non_index,
            type: :options,
          )
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Options only allowed on index")
      end

      it "raises RiskViolation when risk reward is invalid" do
        args = base_args.merge("stop_loss" => 120, "target" => 100)

        expect do
          described_class.run!(
            context: context,
            args: args,
            instrument: instrument,
            type: :options,
          )
        end.to raise_error(Dhanhq::Mcp::Errors::RiskViolation, "Invalid risk-reward")
      end
    end
  end
end
