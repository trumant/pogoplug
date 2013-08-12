require_relative 'helper'
module PogoPlug
  class FileTest < Test::Unit::TestCase
    context "File" do
      setup do
        @name = "My file name"
        @id = "WJ0I39hPZfSIgLYSes5u0w"
        @type = File::Type::FILE
        @mimetype = "test/plain"
        @file = File.new(@name, @id, @type)
      end

      should "provide a name" do
        assert_equal(@file.name, @name)
      end

      should "provide an ID" do
        assert_equal(@file.id, @id)
      end

      should "provide a type" do
        assert_equal(@file.type, @type)
      end

      should "provide a size" do
        assert_equal(@file.size, 0)
      end

      should "provide a mimetype" do
        @file.mimetype = @mimetype
        assert_equal(@file.mimetype, @mimetype)
      end

      should "know if its a directory" do
        assert_false(@file.directory?, "File of type File::Type::FILE should not think it is a directory")
        directory = File.new("My folder", "some id value", File::Type::DIRECTORY)
        assert_true(directory.directory?, "File of type File::Type::DIRECTORY should know that it is a directory")
      end
    end
  end
end
