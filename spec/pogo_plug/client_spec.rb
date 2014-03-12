require 'spec/spec_helper'
require 'pogoplug/client'

describe PogoPlug::Client do

  before do
    @client = PogoPlug::Client.new("https://service.pogoplug.com/")
    @username = "gem_test_user@mailinator.com"
    @password = "p@ssw0rd"
  end

  context "#version" do
    it "should provide version info" do
      version = @client.version

      expect(version.version).to be_a(String)
      expect(version.version).not_to be_empty

      expect(version.build_date).to be_a(String)
      expect(version.build_date).not_to be_empty
    end
  end

  context "#login" do
    it "should provide a client instance with a token" do
      token = @client.login(@username, @password)
      expect(token).to be_a(String)
      expect(token).not_to be_empty
    end

    it "should raise an AuthenticationError when invalid credentials are provided" do
      expect do
        @client.login("bad_email_address@mailinator.com", "bad_password")
      end.to raise_error(PogoPlug::AuthenticationError)
    end
  end

  context 'logged in' do
    before do
      @client.login(@username, @password)
    end

    context "#devices" do
      it "should provide a list of PogoPlug devices belonging to the user" do
        devices = @client.devices
        expect(devices).not_to be_nil

        first_device = devices.first
        expect(first_device).to be_a(PogoPlug::Device)
        expect(first_device.services).not_to be_empty
      end
    end

    context "#services" do
      it "should provide a list of PogoPlug services available to the user" do
        services = @client.services
        expect(services).not_to be_nil
        expect(services).to be_kind_of(Enumerable)
      end
    end

    context 'user data' do
      it "should list the user data" do
        response = @client.user_data
        expect(response["user"]["userid"]).to eq("1a3edf8b7a987226ec0840f37bf35cc5")
      end
    end

  end

end

