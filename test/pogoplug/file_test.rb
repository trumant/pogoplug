require_relative 'helper'

module PogoPlug
  class FileTest < Test::Unit::TestCase
    context "File" do
      setup do
        @name = "My file name"
        @id = "WJ0I39hPZfSIgLYSes5u0w"
        @type = File::Type::FILE
        @mimetype = "test/plain"
        @file = File.new(name: @name, id: @id, type: @type)
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
        directory = File.new(name: "My folder", id: "some id value", type: File::Type::DIRECTORY)
        assert_true(directory.directory?, "File of type File::Type::DIRECTORY should know that it is a directory")
      end

      should "be able to build instances from JSON" do
        json = %q{
          {
            "fileid": "WJ0I39hPZfSIgLYSes5u0w",
            "type": "0",
            "name": "bar.txt",
            "parentid": "0",
            "mimetype": "text/plain",
            "size": "0",
            "ctime": "1376082434000",
            "mtime": "1376082434000",
            "origtime": "1376082434000",
            "xcstamp": "",
            "tnstamp": "",
            "mdstamp": "",
            "streamtype": "full",
            "thumbnail": "",
            "preview": "",
            "stream": "",
            "livestream": "",
            "flvstream": "",
            "properties": {
              "origin": ""
            },
            "metaver": "0",
            "filename": "bar.txt",
            "mediatype": "text"
          }
        }
        file = File.from_json(JSON.parse(json))
        assert_false(file.directory?)
        assert_true(file.file?)
        assert_equal(file.mimetype, "text/plain")
        assert_equal(file.size, 0)
        assert_equal(file.id, "WJ0I39hPZfSIgLYSes5u0w")
        assert_equal(file.name, "bar.txt")
        assert_equal(file.parent_id, "0")
      end
    end
  end
end
