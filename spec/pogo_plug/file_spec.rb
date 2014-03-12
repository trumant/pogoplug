require 'spec_helper'
require 'pogoplug/file'

describe PogoPlug::File do
  context "File" do

    it "should provide nane, id, type, size and mimetype" do
      @name = "My file name"
      @id = "WJ0I39hPZfSIgLYSes5u0w"
      @type = PogoPlug::File::Type::FILE
      @mimetype = "test/plain"
      @file = PogoPlug::File.new(name: @name, id: @id, type: @type, mimetype: @mimetype)

      expect(@file).not_to be_directory
      expect(@file.name).to eq(@name)
      expect(@file.id).to eq(@id)
      expect(@file.type).to eq(@type)
      expect(@file.mimetype).to eq(@mimetype)
    end

    it "should know if its a directory" do
      directory = PogoPlug::File.new(name: "My folder", id: "some id value", type: PogoPlug::File::Type::DIRECTORY)
      expect(directory).to be_directory
    end

    it "should be able to build instances from JSON" do
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
      file = PogoPlug::File.from_json(JSON.parse(json))
      expect(file).not_to be_directory
      expect(file).to be_file
      expect(file.mimetype).to eq('text/plain')
      expect(file.size).to eq(0)
      expect(file.id).to eq("WJ0I39hPZfSIgLYSes5u0w")
      expect(file.name).to eq('bar.txt')
      expect(file.parent_id).to eq('0')
    end
  end
end