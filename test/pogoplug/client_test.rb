require_relative 'helper'

class ClientTest < Test::Unit::TestCase
  context "Client" do
    setup do
      @client = PogoPlug::Client.new
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
        token = @client.login("gem_test_user@mailinator.com", "p@ssw0rd")
        assert(token.is_a?(String) && !token.empty?, "Auth token is missing")
      end
    end
  end
end
