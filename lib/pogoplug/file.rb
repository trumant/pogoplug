module PogoPlug
  class File
    attr_accessor :name, :id, :type, :size, :mimetype, :parent_id

    module Type
      FILE = 0
      DIRECTORY = 1
      STREAM = 2
      SYMBOLIC_LINK = 3
    end

    include HashInitializer

    def directory?
      @type == File::Type::DIRECTORY
    end

    def file?
      @type == File::Type::FILE
    end

    def size
      @size || 0
    end

    def self.from_json(json)
      File.new(
        name: json['name'],
        id: json['fileid'],
        type: json['type'].to_i,
        mimetype: json['mimetype'],
        parent_id: json['parentid'],
        size: json['size'].to_i
      )
    end
  end
end
