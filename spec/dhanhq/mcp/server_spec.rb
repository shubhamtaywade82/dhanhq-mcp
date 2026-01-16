# frozen_string_literal: true

require "rack"

RSpec.describe Dhanhq::Mcp::Server do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:context_provider) { ->(_req) { context } }
  let(:server) { described_class.new(context_provider: context_provider) }

  describe "#call" do
    context "with tools/list method" do
      it "returns tool specifications" do
        env = build_rack_env({ "method" => "tools/list" })

        status, headers, body = server.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/json")
        parsed = JSON.parse(body.first)
        expect(parsed["result"]).to be_an(Array)
        expect(parsed["result"].first["name"]).to eq("portfolio.holdings")
      end
    end

    context "with tools/call method" do
      it "routes to portfolio tool" do
        allow(DhanHQ::Models::Holding).to receive(:all).and_return([{ symbol: "TCS" }])
        payload = {
          "method" => "tools/call",
          "params" => {
            "name" => "portfolio.holdings",
            "arguments" => {},
          },
        }
        env = build_rack_env(payload)

        status, _, body = server.call(env)

        expect(status).to eq(200)
        parsed = JSON.parse(body.first)
        expect(parsed["result"]).to eq([{ "symbol" => "TCS" }])
      end

      it "handles missing arguments gracefully" do
        allow(DhanHQ::Models::Holding).to receive(:all).and_return([])
        payload = {
          "method" => "tools/call",
          "params" => {
            "name" => "portfolio.holdings",
          },
        }
        env = build_rack_env(payload)

        status, _, body = server.call(env)

        expect(status).to eq(200)
        parsed = JSON.parse(body.first)
        expect(parsed["result"]).to eq([])
      end

      it "returns error for unknown tool" do
        payload = {
          "method" => "tools/call",
          "params" => {
            "name" => "invalid.tool",
            "arguments" => {},
          },
        }
        env = build_rack_env(payload)

        status, _, body = server.call(env)

        expect(status).to eq(200)
        parsed = JSON.parse(body.first)
        expect(parsed["error"]).not_to be_nil
        expect(parsed["error"]["message"]).to include("invalid.tool")
      end
    end

    context "with unknown method" do
      it "returns error response" do
        env = build_rack_env({ "method" => "unknown/method" })

        status, _, body = server.call(env)

        expect(status).to eq(200)
        parsed = JSON.parse(body.first)
        expect(parsed["error"]).not_to be_nil
        expect(parsed["error"]["message"]).to eq("Unknown MCP method")
      end
    end

    context "with invalid JSON" do
      it "returns error response" do
        env = {
          "REQUEST_METHOD" => "POST",
          "rack.input" => StringIO.new("invalid json"),
        }

        status, _, body = server.call(env)

        expect(status).to eq(200)
        parsed = JSON.parse(body.first)
        expect(parsed["error"]).not_to be_nil
      end
    end
  end

  def build_rack_env(payload)
    {
      "REQUEST_METHOD" => "POST",
      "rack.input" => StringIO.new(JSON.dump(payload)),
    }
  end
end
