require 'spec_helper'
require 'pogoplug/file_listing'

describe PogoPlug::FileListing do
  include TestFileUtils

  it "should provide the number of files in the listing" do
    @size = 2
    @offset = 0
    @file_listing = PogoPlug::FileListing.new(offset: @offset, total_count: @size)
    expect(@file_listing.total_count).to eq(@size)
  end

  context "from_json" do
    it "should produce a FileListing instance when given JSON" do
      json = contents_of("file_listing_example.json")
      listing = PogoPlug::FileListing.from_json(JSON::parse(json))
      expect(listing.size).to eq(4)
      expect(listing.offset).to eq(0)
      expect(listing.total_count).to eq(4)
      expect(listing.files).not_to be_nil
      expect(listing).to be_kind_of(Enumerable)
      expect(listing.files.size).to eq(4)
      expect(listing).not_to be_empty
    end

    it "should produce a file listing from json returned for empty folder" do
      json = "{\"pageoffset\":\"0\",\"count\":\"0\",\"totalcount\":\"0\"}"
      listing = PogoPlug::FileListing.from_json(JSON::parse(json))

      expect(listing.size).to eq(0)
      expect(listing.offset).to eq(0)
      expect(listing.total_count).to eq(0)
      expect(listing).to be_empty
    end
  end

end

