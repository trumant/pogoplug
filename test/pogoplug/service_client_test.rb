require_relative 'helper'
require 'securerandom'
require 'tempfile'

module PogoPlug
  class ServiceClientTest < Test::Unit::TestCase
    NAME = "Pogoplug Cloud"

    PATH = ::File.expand_path('../../test_file.txt', __FILE__)
    CONTENT = IO.read(PATH)

    PATH_2 = ::File.expand_path('../../test_file_2.txt', __FILE__)
    CONTENT_2 = IO.read(PATH_2)

    def generate_name
      SecureRandom.hex
    end

    context 'service client' do

      setup do
        WebMock.allow_net_connect!
        client = PogoPlug::Client.new("https://service.pogoplug.com/")
        @username = "gem_test_user@mailinator.com"
        @password = "p@ssw0rd"
        @token = client.login(@username, @password)
        @device = client.devices.first { |d| d.name == NAME }
        raise 'there should have been a device here' if @device.nil?
        @client = @device.services.first.client
        name = generate_name
        @parent = @client.create_directory(name)
      end

      teardown do
        @client.delete(@parent.id)
      end

      should "create a directory" do
        name = generate_name
        directory = @client.create_directory(name, @parent.id)
        assert_equal(name, directory.name)
        assert_not_nil(directory.id)
      end

      should 'upload a file' do
        ::File.open(PATH) do |f|
          name = "#{generate_name}.txt"
          file = @client.create_file(name, @parent.id, f)
          assert_equal(CONTENT, @client.download(file))
        end
      end

      should 'download a file to an specific path' do
        ::File.open(PATH) do |f|
          name = "#{generate_name}.txt"
          file = @client.create_file(name, @parent.id, f)

          destination = Tempfile.new("test")
          @client.download_to(file, destination.path)
          assert_equal(CONTENT, IO.read(destination.path))
        end
      end

      should "get a file by it' id" do
        name = generate_name
        directory = @client.create_directory(name, @parent.id)
        stored = @client.find_by_id!(directory.id)
        assert_equal(name, stored.name)
        assert_equal(directory.id, stored.id)
      end

      should "allow create_entity to be called twice" do
        name = "#{generate_name}.txt"

        result = ::File.open(PATH) do |f|
          @client.create_file(name, @parent.id, f)
        end

        updated = ::File.open(PATH_2) do |f|
          @client.create_entity(result, f)
        end

        assert_equal(result.id, updated.id)
        assert_equal(@parent.id, updated.parent_id)
        assert_equal(CONTENT_2, @client.download(result))
      end

      should "delete a file correctly" do
        name = "#{generate_name}.txt"

        result = ::File.open(PATH) do |f|
          @client.create_file(name, @parent.id, f)
        end

        @client.delete(result.id)

        assert_raise PogoPlug::NotFoundError do
          @client.find_by_id!(result.id)
        end
      end

      should "ignore the delete if it does not exist" do
        name = generate_name
        item = @client.create_directory(name, @parent.id)

        @client.delete(item.id)
        assert_nil(@client.delete_if_exists(item.id))
      end

      should "delete the item if it exists" do
        name = generate_name
        item = @client.create_directory(name, @parent.id)

        @client.delete_if_exists(item.id)
        assert_nil(@client.find_by_id(item.id))
      end

      should "list files from directory" do
        first = generate_name
        second = generate_name

        @client.create_directory(first, @parent.id)
        @client.create_directory(second, @parent.id)

        listing = @client.files_from_parent(@parent.id)

        assert_true(!!listing.find { |f| f.name == first })
        assert_true(!!listing.find { |f| f.name == second })
        assert_equal(2, listing.total_count)
        assert_equal(0, listing.offset)
      end

      should "create the directory if it is not there" do
        name = generate_name
        result = @client.create_entity_if_needed(name, @parent.id)
        assert_equal(name, result.name)
        assert_equal(@parent.id, result.parent_id)
      end

      should "return the directory itself is it is already there" do
        name = generate_name
        result = @client.create_directory(name, @parent.id)
        other = @client.create_entity_if_needed(name, @parent.id)
        assert_equal(result.id, other.id)
      end

      should 'create a file if it is not there already' do
        name = "#{generate_name}.txt"

        result = ::File.open(PATH) do |f|
          @client.create_entity_if_needed(name, @parent.id, f)
        end

        assert_equal(CONTENT, @client.download(result))
      end

      should 'update the file if it is already there' do
        name = "#{generate_name}.txt"

        result = ::File.open(PATH) do |f|
          @client.create_file(name, @parent.id, f)
        end

        updated = ::File.open(PATH_2) do |f|
          @client.create_entity_if_needed(name, @parent.id, f)
        end

        assert_equal(result.id, updated.id)
        assert_equal(@parent.id, updated.parent_id)
        assert_equal(CONTENT_2, @client.download(result))
      end

      should "rename the file inside the same folder" do
        name = "file.txt"
        other_name = "other_file.txt"

        result = ::File.open(PATH) do |f|
          @client.create_file(name, @parent.id, f)
        end

        @client.move(result.id, @parent.id, other_name)

        moved = @client.find_by_name(other_name, @parent.id)

        assert_equal(result.id, moved.id)
        assert_nil(@client.find_by_name( name, @parent.id ))
        assert_equal(CONTENT, @client.download(moved))
      end

      should "rename the file across folders" do
        name = "file.txt"
        other_folder = 'other folder'

        result = ::File.open(PATH) do |f|
          @client.create_file(name, @parent.id, f)
        end

        destination =  @client.create_directory(other_folder, @parent.id)

        move_result = @client.move(result.id, destination.id, result.name)

        moved = @client.find_by_name!(result.name, destination.id)

        assert_equal(
          result.id,
          moved.id)
        assert_nil(@client.find_by_name( name, @parent.id ))
        assert_equal(CONTENT, @client.download(moved))
      end

    end

  end
end