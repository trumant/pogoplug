require 'forwardable'
require 'pogoplug/hash_initializer'

module PogoPlug
  class FileListing
    include HashInitializer
    include Enumerable
    extend Forwardable

    def_delegators :files, :each, :[], :size, :empty?, :first, :last
    attr_accessor :offset, :total_count, :files

    def files
      @files ||= Array.new
    end

    def blank?
      self.total_count == 0
    end

    def self.from_json(json)
      listing = FileListing.new(
        offset: json['pageoffset'].to_i,
        total_count: json['totalcount'].to_i
      )
      if json['files']
        json['files'].each do |f|
          listing.files << File.from_json(f)
        end
      end
      listing
    end

  end
end
