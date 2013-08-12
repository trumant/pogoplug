module PogoPlug
  class FileListing
    attr_accessor :size, :offset, :total_count, :files

    def initialize(size, offset)
      @size = size
      @offset = offset
      @total_count = 0
      @files = []
    end

    def self.from_json(json)
      listing = FileListing.new(json['count'].to_i, json['pageoffset'].to_i)
      listing.total_count = json['totalcount'].to_i
      json['files'].each do |f|
        listing.files << File.from_json(f)
      end
      listing
    end
  end
end
