require_relative 'helper'

class ClientTest < Test::Unit::TestCase
  context "Client" do
    setup do
      @client = PogoPlug::Client.new
      @username = "gem_test_user@mailinator.com"
      @password = "p@ssw0rd"
    end

    context "#version" do
      should "provide version info" do
        version = @client.version
        assert_not_nil version
        assert(version.version.is_a?(String) && !version.version.empty?, "Version number is missing.")
        assert(version.build_date.is_a?(String) && !version.build_date.empty?, "Build date is missing")
      end
    end

    context "#login" do
      should "provide a token" do
        token = @client.login(@username, @password)
        assert(token.is_a?(String) && !token.empty?, "Auth token is missing")
      end

      should "raise an AuthenticationError when invalid credentials are provided" do
        assert_raise(PogoPlug::AuthenticationError, "AuthenticationError should have been raised") do
          @client.login("bad_email_address@mailinator.com", "bad_password")
        end
      end
    end

    context "#devices" do
      setup do
        @token = @client.login(@username, @password)
      end

      should "provide a list of PogoPlug devices belonging to the user" do
        devices = @client.devices(@client.login(@username, @password))
        assert_not_nil(devices, "Devices are missing")
      end
    end
  end
end
