# frozen_string_literal: true

RSpec.describe Dhanhq::Mcp::Tools::Account do
  let(:client) { double("client") }
  let(:context) { Dhanhq::Mcp::Context.new(client: client) }
  let(:tool) { described_class.new(context) }
  let(:ip_resource) { instance_double(DhanHQ::Resources::IPSetup) }

  before do
    allow(DhanHQ::Resources::IPSetup).to receive(:new).and_return(ip_resource)
  end

  describe "#get_ip" do
    it "fetches and normalizes the configured IPs" do
      allow(ip_resource).to receive(:current).and_return(
        "primaryIP" => "1.2.3.4",
        "secondaryIP" => "5.6.7.8",
      )

      result = tool.get_ip

      expect(result).to eq(primary_ip: "1.2.3.4", secondary_ip: "5.6.7.8")
    end

    it "returns an error hash when the client raises" do
      allow(ip_resource).to receive(:current).and_raise(DhanHQ::AuthenticationError, "token expired")

      expect(tool.get_ip).to eq(error: "token expired")
    end
  end

  describe "#set_ip" do
    it "sets the static IP via IPSetup#set" do
      allow(ip_resource).to receive(:set)
        .with(ip: "1.2.3.4", ip_flag: "PRIMARY", dhan_client_id: "1000000001")
        .and_return("message" => "IP set successfully")

      result = tool.set_ip("dhan_client_id" => "1000000001", "ip" => "1.2.3.4", "ip_flag" => "PRIMARY")

      expect(result[:success]).to be true
      expect(result[:message]).to eq("IP set successfully")
    end

    it "defaults ip_flag to PRIMARY when omitted" do
      allow(ip_resource).to receive(:set)
        .with(ip: "1.2.3.4", ip_flag: "PRIMARY", dhan_client_id: nil)
        .and_return({})

      tool.set_ip("ip" => "1.2.3.4")

      expect(ip_resource).to have_received(:set).with(ip: "1.2.3.4", ip_flag: "PRIMARY", dhan_client_id: nil)
    end

    it "returns a failure hash when the client raises" do
      allow(ip_resource).to receive(:set).and_raise(DhanHQ::Error, "invalid IP")

      expect(tool.set_ip("ip" => "bad")).to eq(success: false, error: "invalid IP")
    end
  end

  describe "#modify_ip" do
    it "updates the static IP via IPSetup#update" do
      allow(ip_resource).to receive(:update)
        .with(ip: "9.9.9.9", ip_flag: "SECONDARY", dhan_client_id: "1000000001")
        .and_return("message" => "IP updated")

      result = tool.modify_ip("dhan_client_id" => "1000000001", "ip" => "9.9.9.9", "ip_flag" => "SECONDARY")

      expect(result[:success]).to be true
      expect(result[:message]).to eq("IP updated")
    end
  end

  describe "#profile" do
    it "fetches and normalizes the user profile" do
      allow(DhanHQ::Resources::Profile).to receive(:new).and_return(
        instance_double(DhanHQ::Resources::Profile, fetch: { "dhanClientId" => "1000000001", "tokenValidity" => "30/03/2026" }),
      )

      result = tool.profile

      expect(result).to eq(dhan_client_id: "1000000001", token_validity: "30/03/2026")
    end

    it "returns an error hash when the client raises" do
      profile_resource = instance_double(DhanHQ::Resources::Profile)
      allow(DhanHQ::Resources::Profile).to receive(:new).and_return(profile_resource)
      allow(profile_resource).to receive(:fetch).and_raise(DhanHQ::AuthenticationError, "token expired")

      expect(tool.profile).to eq(error: "token expired")
    end
  end
end
