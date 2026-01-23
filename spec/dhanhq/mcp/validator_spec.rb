# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Validator do
  describe ".validate!" do
    context "when required arguments are missing" do
      it "raises InvalidArguments" do
        expect do
          described_class.validate!("instrument.find", {})
        end.to raise_error(Dhanhq::Mcp::Errors::InvalidArguments)
      end
    end

    context "when argument types are invalid" do
      it "raises InvalidArguments" do
        args = { "exchange_segment" => "IDX_I", "symbol" => 123 }

        expect do
          described_class.validate!("instrument.find", args)
        end.to raise_error(Dhanhq::Mcp::Errors::InvalidArguments)
      end
    end

    context "when arguments are valid" do
      it "does not raise" do
        args = { "exchange_segment" => "IDX_I", "symbol" => "NIFTY" }

        expect do
          described_class.validate!("instrument.find", args)
        end.not_to raise_error
      end
    end
  end
end
