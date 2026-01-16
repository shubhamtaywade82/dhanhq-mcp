# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Context do
  describe "#initialize" do
    context "with required client parameter" do
      let(:client) { double("client") }

      it "stores client" do
        context = described_class.new(client: client)

        expect(context.client).to eq(client)
      end

      it "stores empty meta when not provided" do
        context = described_class.new(client: client)

        expect(context.meta).to eq({})
      end
    end

    context "with client and meta parameters" do
      let(:client) { double("client") }
      let(:meta) { { user_id: 123, session: "abc" } }

      it "stores both client and meta" do
        context = described_class.new(client: client, meta: meta)

        expect(context.client).to eq(client)
        expect(context.meta).to eq(meta)
      end
    end
  end
end
