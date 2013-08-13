require_relative 'helper'
module PogoPlug
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
          devices = @client.devices(@token)
          assert_not_nil(devices, "Devices are missing")
          first_device = devices.first
          assert_kind_of(PogoPlug::Device, first_device, "Device model instances should be returned")
          assert_false(first_device.services.empty?, "Device services should not be empty")
        end
      end

      context "#services" do
        setup do
          @token = @client.login(@username, @password)
        end

        should "provide a list of PogoPlug services available to the user" do
          services = @client.services(@token)
          assert_not_nil(services, "Services are missing")
          assert_kind_of(Enumerable, services)
        end
      end

      context "#files" do
        setup do
          @token = @client.login(@username, @password)
          @device = @client.devices(@token).first
        end

        should "provide a list of files for a device and service" do
          files = @client.files(@token, @device.id, @device.services.first.id)
          assert_not_nil(files, "Files are missing")
          assert_kind_of(PogoPlug::FileListing, files)
          #assert_false(files.empty?, "Files are not expected to be empty")
        end
      end

      context "#create_directory" do
        setup do
          @token = @client.login(@username, @password)
          @device = @client.devices(@token).first
          @directory_name = "My Test Directory #{rand(1000).to_i}"
          @child_directory_name = "My Test Child Directory #{rand(1000).to_i}"
        end

        should "create a directory under the root" do
          directory = @client.create_directory(@token, @device.id, @device.services.first.id, @directory_name)
          assert_not_nil(directory, "Directory should have been created")
          assert_equal(directory.name, @directory_name, "Directory should have the correct name")
          assert_equal(directory.parent_id, "0", "Directory should be at the root")
          assert_true(directory.directory?, "Directory should be a directory")
        end

        should "create a directory under the specified parent" do
          parent_directory = @client.files(@token, @device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          directory = @client.create_directory(@token, @device.id, @device.services.first.id, @child_directory_name, parent_directory.id)
          assert_not_nil(directory, "Directory should have been created")
          assert_equal(directory.name, @child_directory_name, "Directory should have the correct name")
          assert_equal(directory.parent_id, parent_directory.id, "Directory should be under the correct parent")
          assert_true(directory.directory?, "Directory should be a directory")
        end
      end

      context "#create_file" do
        setup do
          @token = @client.login(@username, @password)
          @device = @client.devices(@token).first
          @file_name = "My test file #{rand(1000).to_i}"
        end

        should "create a file" do
          parent_directory = @client.files(@token, @device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          file = File.new(name: @file_name, type: File::Type::FILE, parent_id: parent_directory.id)
          created_file = @client.create_file(@token, @device.id, @device.services.first.id, file)
          assert_not_nil(created_file, "File should have been created")
        end
      end
    end
  end
end
