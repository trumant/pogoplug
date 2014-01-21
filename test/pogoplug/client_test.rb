require 'tmpdir'

require_relative 'helper'

module PogoPlug
  class ClientTest < Test::Unit::TestCase
    API_HOST = "https://service.pogoplug.com/"
    WebMock.allow_net_connect!

    context "Client" do
      setup do
        @client = PogoPlug::Client.new(API_HOST, true)
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
            second_page = @client.files(@device.id, @device.services.first.id, nil, file_listing.offset + 1)
            assert_equal(file_listing.offset + 1, second_page.offset, "Expecting the second page listing to have the correct offset")
            assert_false(second_page.empty?, "Expecting the second page of files to have some files")
          end
        end

        should "provide a list of files under a specified directory" do
          parent_directory = @client.create_directory(@device.id, @device.services.first.id, "My Test Directory #{SecureRandom.uuid}")
          file_listing = @client.files(@device.id, @device.services.first.id, parent_directory.id)
          assert_not_nil(file_listing, "Files are missing")
          assert_kind_of(PogoPlug::FileListing, file_listing)
          assert_true(file_listing.empty?, "Files are expected to be empty")
        end
      end

      context "#create_directory" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @directory_name = "My Test Directory #{SecureRandom.uuid}"
          @child_directory_name = "My Test Child Directory #{SecureRandom.uuid}"
        end

        should "create a directory under the root" do
          directory = @client.create_directory(@device.id, @device.services.first.id, @directory_name)
          assert_not_nil(directory, "Directory should have been created")
          assert_equal(directory.name, @directory_name, "Directory should have the correct name")
          assert_equal(directory.parent_id, "0", "Directory should be at the root")
          assert_true(directory.directory?, "Directory should be a directory")
        end

        should "create a directory under the specified parent" do
          parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          directory = @client.create_directory(@device.id, @device.services.first.id, @child_directory_name, parent_directory.id)
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
          @file_name = "My test file #{SecureRandom.uuid}"
          @parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          @file_to_create = File.new(name: @file_name, type: File::Type::FILE, parent_id: @parent_directory.id)
        end

        should "create a file handle" do
          created_file = @client.create_file(@device.id, @device.services.first.id, @file_to_create)
          assert_not_nil(created_file, "File should have been created")
          assert_equal(@file_name, created_file.name)
          assert_equal(@file_to_create.type, created_file.type)
          assert_equal(@file_to_create.parent_id, created_file.parent_id)
          assert_not_nil(created_file.id)
        end

        should "create a file handle and attach the bits" do
          test_file = ::File.new(::File.expand_path('../../test_file.txt', __FILE__), 'rb')
          @file_to_create.name = ::File.basename(test_file.path)
          created_file = @client.create_file(@device.id, @device.services.first.id, @file_to_create, test_file)
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
          directory_name = "My test directory #{SecureRandom.uuid}"
          directory = @client.create_file(@device.id, @device.services.first.id, File.new(name: directory_name, type: File::Type::DIRECTORY))
          assert_true(@client.delete(@device.id, @device.services.first.id, directory.id), "Test directory was not deleted")
        end

        should "delete a directory and its children" do
          parent_directory_name = "My test directory #{SecureRandom.uuid}"
          parent_directory = @client.create_file(@device.id, @device.services.first.id, File.new(name: parent_directory_name, type: File::Type::DIRECTORY))

          child_directory_name = "My test child directory"
          child_directory = @client.create_file(@device.id, @device.services.first.id, File.new(name: child_directory_name, type: File::Type::DIRECTORY, parent_id: parent_directory.id))

          assert_true(@client.delete(@device.id, @device.services.first, parent_directory.id), "Test directory was not deleted")

          deleted_directory = @client.files(@device.id, @device.services.first).files.select { |file| file.directory? && file.name == parent_directory_name }.first
          assert_nil(deleted_directory, "Test directory that was supposed to have been deleted is still returned")
        end

        should "delete a file" do
          file_name = "My test file #{SecureRandom.uuid}"
          file_to_create = File.new(name: file_name, type: File::Type::FILE)

          created_file = @client.create_file(@device.id, @device.services.first.id, file_to_create)
          assert_true(@client.delete(@device.id, @device.services.first.id, created_file.id), "File was not deleted")
        end
      end

      context "#move" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @directory_name = "My Test Directory #{SecureRandom.uuid}"
          @child_directory_name = "My Test Child Directory #{SecureRandom.uuid}"
        end

        should "move a directory to the root" do
          parent_directory = @client.files(@device.id, @device.services.first.id).files.select { |file| file.directory? }.first
          directory = @client.create_directory(@device.id, @device.services.first.id, @child_directory_name, parent_directory.id)
          assert_not_nil(@client.move(@device.id, @device.services.first.id, directory, 0), "Directory was not moved to the root")
        end

        should "move a directory" do
          parent_directory = @client.create_directory(@device.id, @device.services.first.id, @directory_name)
          directory = @client.create_directory(@device.id, @device.services.first.id, @child_directory_name, 0)
          assert_not_nil(@client.move(@device.id, @device.services.first.id, directory, parent_directory.id), "Directory was not moved")
        end

        should "move a file" do
          directory = @client.create_directory(@device.id, @device.services.first.id, @directory_name)

          test_file = ::File.new(::File.expand_path('../../test_file.txt', __FILE__), 'rb')
          file_to_create = File.new(name: ::File.basename(test_file.path), type: File::Type::FILE, parent_id: 0)
          created_file = @client.create_file(@device.id, @device.services.first.id, file_to_create, test_file)
          assert_not_nil(created_file)
          assert_equal(test_file.size, created_file.size)

          assert_not_nil(@client.move(@device.id, @device.services.first.id, created_file, directory.id), "File was not moved")
        end

        should "raise a DuplicateNameError when attempting to move a file to a directory containing a file of the same name" do
          file = mock("PogoPlug::File")
          file.stubs(:id).returns("some_id_value")
          file.stubs(:name).returns("some_file_name.jpg")

          stub_request(:any, /.*pogoplug.*/)
            .to_return(
              body: { "HB-EXCEPTION" => { ecode: 808, message: "File Exists" } }.to_json,
              status: 200,
              headers: { "Content-Type" => "application/x-javascript;charset=utf-8" }
            )
          assert_raise(PogoPlug::DuplicateNameError, "DuplicateNameError should have been raised") do
            @client.move(@device.id, @device.services.first.id, file, nil)
          end
        end
      end

      context "#file" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
        end

        should "raise a NotFoundError when attempting to get file metadata for a missing file" do
          stub_request(:any, /.*pogoplug.*/)
            .to_return(
              body: { "HB-EXCEPTION" => { ecode: 804, message: "No such file" } }.to_json,
              status: 500,
              headers: { "Content-Type" => "application/x-javascript;charset=utf-8" }
            )
          assert_raise(PogoPlug::NotFoundError, "NotFoundError should have been raised") do
            @client.file(@device.id, @device.services.first.id, "not_a_valid_file_id")
          end
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

      context "#search_file_by_name" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @service = @device.services.first
        end

        should "find a file by name" do
          parent_directory_name = "My test directory #{SecureRandom.uuid}"
          parent_directory = @client.create_file(@device.id, @device.services.first.id, File.new(name: parent_directory_name, type: File::Type::DIRECTORY))

          child_directory_name = "My test child directory name #{SecureRandom.uuid}"
          child_directory = @client.create_file(@device.id, @device.services.first.id, File.new(name: child_directory_name, type: File::Type::DIRECTORY, parent_id: parent_directory.id))
          assert_equal(@client.search_file_by_name(@device.id, @service.id, child_directory_name).parent_id, child_directory.parent_id)
        end
      end

      context "#download_to" do
        setup do
          @client.login(@username, @password)
          @device = @client.devices.first
          @service = @device.services.first
          @fileListing = @client.files(@device.id, @service.id)
        end

        should "fetch the file specified" do
          file_to_download = @fileListing.files.select { |f| f.file? }.first
          if file_to_download
            destination = "#{Dir.tmpdir}/#{file_to_download.name}"
            io = @client.download_to(@device.id, @service.id, file_to_download, destination)
            assert_equal(file_to_download.size, ::File.open(destination).size, "File should be the same size as the descriptor said it would be")
          end
        end
      end
    end
  end
end
