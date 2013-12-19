require_relative 'helper'
module PogoPlug
  class ClientTest < Test::Unit::TestCase
    context "Client" do
      setup do
        @client = PogoPlug::Client.new("https://service.pogoplug.com/svc/api/json", true)
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
          logged_in_client = @client.login(@username, @password)
          assert(logged_in_client.token.is_a?(String) && !logged_in_client.token.empty?, "Auth token is missing")
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

      context "#files" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
        end

        should "provide a list of files for a device and service" do
          files = @client.files(@device.id, @device.services.first.id)
          assert_not_nil(files, "Files are missing")
          assert_kind_of(PogoPlug::FileListing, files)
          assert_false(files.empty?, "Files are not expected to be empty")
        end

        should "provide a means of paging through the files in the listing" do
          file_listing = @client.files(@device.id, @device.services.first.id)
          # dependent on previous test runs for us to have more than one page of files in the listing
          if file_listing.total_count > file_listing.size
            second_page = @client.files(@device.id, @device.services.first.id, file_listing.offset + 1)
            assert_equal(file_listing.offset + 1, second_page.offset, "Expecting the second page listing to have the correct offset")
            assert_false(second_page.empty?, "Expecting the second page of files to have some files")
          end
        end
      end

      context "#create_directory" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @directory_name = "My Test Directory #{rand(1000).to_i}"
          @child_directory_name = "My Test Child Directory #{rand(1000).to_i}"
        end

        should "create a directory under the root" do
          directory = @client.create_directory(@device.id, @device.services.first, @directory_name)
          assert_not_nil(directory, "Directory should have been created")
          assert_equal(directory.name, @directory_name, "Directory should have the correct name")
          assert_equal(directory.parent_id, "0", "Directory should be at the root")
          assert_true(directory.directory?, "Directory should be a directory")
        end

        should "create a directory under the specified parent" do
          parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          directory = @client.create_directory(@device.id, @device.services.first, @child_directory_name, parent_directory.id)
          assert_not_nil(directory, "Directory should have been created")
          assert_equal(directory.name, @child_directory_name, "Directory should have the correct name")
          assert_equal(directory.parent_id, parent_directory.id, "Directory should be under the correct parent")
          assert_true(directory.directory?, "Directory should be a directory")
        end
      end

      context "#create_file" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @file_name = "My test file #{rand(1000).to_i}"
          @parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          @file_to_create = File.new(name: @file_name, type: File::Type::FILE, parent_id: @parent_directory.id)
        end

        should "create a file handle" do
          created_file = @client.create_file(@device.id, @device.services.first, @file_to_create)
          assert_not_nil(created_file, "File should have been created")
          assert_equal(@file_name, created_file.name)
          assert_equal(@file_to_create.type, created_file.type)
          assert_equal(@file_to_create.parent_id, created_file.parent_id)
          assert_not_nil(created_file.id)
        end

        should "create a file handle and attach the bits" do
          test_file = ::File.new(::File.expand_path('../../test_file.txt', __FILE__), 'rb')
          @file_to_create.name = ::File.basename(test_file.path)
          created_file = @client.create_file(@device.id, @device.services.first, @file_to_create, test_file)
          assert_not_nil(created_file)
          assert_equal(test_file.size, created_file.size)
        end
      end

      context "#delete" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
        end

        should "delete an empty directory" do
          directory_name = "My test directory #{rand(1000).to_i}"
          directory = @client.create_file(@device.id, @device.services.first, File.new(name: directory_name, type: File::Type::DIRECTORY))
          created_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? && file.name == directory_name }.first

          assert_not_nil(created_directory, "Test directory was not created")
          assert_true(@client.delete(@device.id, @device.services.first.id, directory), "Test directory was not deleted")

          deleted_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? && file.name == directory_name }.first
          assert_nil(deleted_directory, "Test directory that was supposed to have been deleted is still returned")
        end

        should "delete a directory and its children" do
          parent_directory_name = "My test directory #{rand(1000).to_i}"
          parent_directory = @client.create_file(@device.id, @device.services.first, File.new(name: parent_directory_name, type: File::Type::DIRECTORY))

          child_directory_name = "My test child directory"
          child_directory = @client.create_file(@device.id, @device.services.first, File.new(name: child_directory_name, type: File::Type::DIRECTORY, parent_id: parent_directory.id))

          assert_true(@client.delete(@device.id, @device.services.first.id, parent_directory), "Test directory was not deleted")

          deleted_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? && file.name == parent_directory_name }.first
          assert_nil(deleted_directory, "Test directory that was supposed to have been deleted is still returned")
        end

        should "delete a file" do
          file_name = "My test file #{rand(1000).to_i}"
          file_to_create = File.new(name: file_name, type: File::Type::FILE)

          created_file = @client.create_file(@device.id, @device.services.first, file_to_create)
          assert_true(@client.delete(@device.id, @device.services.first.id, created_file), "File was not deleted")
        end
      end

      context "#move" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @directory_name = "My Test Directory #{rand(1000).to_i}"
          @child_directory_name = "My Test Child Directory #{rand(1000).to_i}"
        end

        should "move a directory to the root" do
          parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          directory = @client.create_directory(@device.id, @device.services.first, @child_directory_name, parent_directory.id)
          assert_true(@client.move(@device.id, @device.services.first.id, directory, 0), "Directory was not moved to the root")
        end

        should "move a directory" do
          parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          directory = @client.create_directory(@device.id, @device.services.first, @child_directory_name, 0)
          assert_true(@client.move(@device.id, @device.services.first.id, directory, parent_directory.id), "Directory was not moved")
        end

        should "move a file" do
          parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          test_file = ::File.new(::File.expand_path('../../test_file.txt', __FILE__), 'rb')
          file_to_create = File.new(name: ::File.basename(test_file.path), type: File::Type::FILE, parent_id: 0)
          created_file = @client.create_file(@device.id, @device.services.first, @file_to_create, test_file)
          assert_not_nil(created_file)
          assert_equal(test_file.size, created_file.size)

          assert_true(@client.move(@device.id, @device.services.first.id, created_file, parent_directory.id), "File was not moved")
        end
      end

      context "#copy" do
      end

      context "#download" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @service = @device.services.first
          @fileListing = @client.files(@device.id, @service.id)
        end

        should "fetch the file specified" do
          file_to_download = @fileListing.files.select { |f| f.file? }.first
          if file_to_download
            io = @client.download(@device.id, @service, file_to_download)
            assert_equal(file_to_download.size, io.size, "File should be the same size as the descriptor said it would be")
          end
        end

        should "refuse to download a directory" do
          file_to_download = @fileListing.files.select { |f| f.directory? }.first
          if file_to_download
            assert_raise(RuntimeError, "Directories cannot be downloaded") do
              @client.download(@device.id, @service, file_to_download)
            end
          end
        end
      end
    end
  end
end
