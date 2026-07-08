# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::ConditionalTriggers do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:tool) { described_class.new(context) }

  let(:alert) do
    double(
      "alert_order",
      id: "999",
      alert_id: "999",
      exchange_segment: "NSE_EQ",
      security_id: "11536",
      condition: { comparison_type: "PRICE_WITH_VALUE" },
      trigger_price: 1400.0,
      order_type: "LIMIT",
      transaction_type: "BUY",
      quantity: 5,
      price: 1405.0,
      status: "ACTIVE",
      created_at: "2026-01-01",
    )
  end

  describe "#place" do
    it "creates an alert order via DhanHQ::Models::AlertOrder" do
      args = { "condition" => { "comparison_type" => "PRICE_WITH_VALUE" }, "orders" => [] }
      allow(DhanHQ::Models::AlertOrder).to receive(:create).with(args).and_return(alert)

      result = tool.place(args)

      expect(result[:success]).to be true
      expect(result[:alert_id]).to eq("999")
    end

    it "returns a failure hash when creation fails" do
      allow(DhanHQ::Models::AlertOrder).to receive(:create).and_return(nil)

      result = tool.place({})

      expect(result[:success]).to be false
    end

    it "returns a failure hash when the client raises" do
      allow(DhanHQ::Models::AlertOrder).to receive(:create).and_raise(DhanHQ::ValidationError, "bad payload")

      result = tool.place({})

      expect(result).to eq(success: false, error: "bad payload")
    end
  end

  describe "#modify" do
    it "requires alert_id" do
      expect(tool.modify({})).to eq(error: "alert_id is required")
    end

    it "modifies an existing alert order" do
      allow(DhanHQ::Models::AlertOrder).to receive(:modify)
        .with("999", { "comparing_value" => 300 })
        .and_return(alert)

      result = tool.modify("alert_id" => "999", "comparing_value" => 300)

      expect(result[:success]).to be true
      expect(result[:alert_id]).to eq("999")
    end
  end

  describe "#delete" do
    it "requires alert_id" do
      expect(tool.delete({})).to eq(error: "alert_id is required")
    end

    it "destroys the alert order when found" do
      allow(DhanHQ::Models::AlertOrder).to receive(:find).with("999").and_return(alert)
      allow(alert).to receive(:destroy).and_return(true)

      result = tool.delete("alert_id" => "999")

      expect(result).to eq(success: true, alert_id: "999")
    end

    it "reports not found when the alert doesn't exist" do
      allow(DhanHQ::Models::AlertOrder).to receive(:find).with("999").and_return(nil)

      result = tool.delete("alert_id" => "999")

      expect(result[:success]).to be false
    end
  end

  describe "#all" do
    it "lists all conditional triggers" do
      allow(DhanHQ::Models::AlertOrder).to receive(:all).and_return([alert])

      result = tool.all

      expect(result.length).to eq(1)
      expect(result.first[:alert_id]).to eq("999")
    end
  end

  describe "#get" do
    it "requires alert_id" do
      expect(tool.get({})).to eq(error: "alert_id is required")
    end

    it "returns the conditional trigger when found" do
      allow(DhanHQ::Models::AlertOrder).to receive(:find).with("999").and_return(alert)

      result = tool.get("alert_id" => "999")

      expect(result[:alert_id]).to eq("999")
    end

    it "returns an error when not found" do
      allow(DhanHQ::Models::AlertOrder).to receive(:find).with("999").and_return(nil)

      result = tool.get("alert_id" => "999")

      expect(result).to eq(error: "Conditional trigger not found")
    end
  end
end
