require 'tmpdir'

require_relative 'helper'

module PogoPlug
  class ClientTest < Test::Unit::TestCase
    API_HOST = "https://service.pogoplug.com/"

    context "Client" do
      setup do
        @client = PogoPlug::Client.new(API_HOST)
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
        should "provide a client instance with a token" do
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
          @client.login(@username, @password)
        end

        should "provide a list of PogoPlug devices belonging to the user" do
          devices = @client.devices
          assert_not_nil(devices, "Devices are missing")
          first_device = devices.first
          assert_kind_of(PogoPlug::Device, first_device, "Device model instances should be returned")
          assert_false(first_device.services.empty?, "Device services should not be empty")
        end
      end

      context "#services" do
        setup do
          @client.login(@username, @password)
        end

        should "provide a list of PogoPlug services available to the user" do
          services = @client.services
          assert_not_nil(services, "Services are missing")
          assert_kind_of(Enumerable, services)
        end
      end

      context 'user data' do
        setup do
          @client.login(@username, @password)
        end

        should "list the user data" do
          response = @client.user_data
          assert_equal("1a3edf8b7a987226ec0840f37bf35cc5", response["user"]["userid"] )
        end
      end

    end
  end
end
