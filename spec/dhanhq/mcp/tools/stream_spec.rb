# frozen_string_literal: true

RSpec.describe "Streaming tools" do
  let(:client) { double("client") }
  let(:registry) { Dhanhq::Mcp::Stream::Registry.new }
  let(:context) { Dhanhq::Mcp::Context.new(client: client, meta: { stream_registry: registry }) }

  describe "stream.subscribe" do
    context "when subscribing to an instrument" do
      it "adds a subscription to the registry" do
        Dhanhq::Mcp::Tools::Stream::Subscribe.new(context).call(
          "exchange_segment" => "IDX_I",
          "symbol" => "NIFTY",
          "feed_type" => "LTP",
        )

        actual_count = registry.all.length
        expected_count = 1

        expect(actual_count).to eq(expected_count)
      end
    end
  end

  describe "stream.unsubscribe" do
    context "when the subscription exists" do
      it "removes the subscription from the registry" do
        subscription = Dhanhq::Mcp::Tools::Stream::Subscribe.new(context).call(
          "exchange_segment" => "IDX_I",
          "symbol" => "NIFTY",
          "feed_type" => "LTP",
        )

        Dhanhq::Mcp::Tools::Stream::Unsubscribe.new(context).call(
          "subscription_id" => subscription[:subscription_id],
        )

        actual_subscriptions = registry.all
        expected_subscriptions = []

        expect(actual_subscriptions).to eq(expected_subscriptions)
      end
    end

    context "when the subscription is unknown" do
      it "raises InvalidArguments" do
        expect do
          Dhanhq::Mcp::Tools::Stream::Unsubscribe.new(context).call(
            "subscription_id" => "missing",
          )
        end.to raise_error(Dhanhq::Mcp::Errors::InvalidArguments, "Unknown subscription")
      end
    end
  end

  describe "stream.status" do
    context "when subscriptions are present" do
      it "returns the active subscriptions" do
        Dhanhq::Mcp::Tools::Stream::Subscribe.new(context).call(
          "exchange_segment" => "IDX_I",
          "symbol" => "NIFTY",
          "feed_type" => "LTP",
        )

        actual_subscriptions = Dhanhq::Mcp::Tools::Stream::Status.new(context).call

        expect(actual_subscriptions.length).to eq(1)
      end
    end
  end
end
