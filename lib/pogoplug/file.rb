module PogoPlug
  class File
    attr_accessor :name, :id, :type, :size, :mimetype, :parent_id

    module Type
      FILE = 0
      DIRECTORY = 1
      STREAM = 2
      SYMBOLIC_LINK = 3
    end

    def initialize(name, id, type)
      @name = name
      @id = id
      @type = type
      @size = 0
    end

    def directory?
      @type == File::Type::DIRECTORY
    end

    def file?
      @type == File::Type::FILE
    end

    def self.from_json(json)
      file = File.new(json['name'], json['fileid'], json['type'].to_i)
      file.mimetype = json['mimetype']
      file.parent_id = json['parentid']
      file
    end
  end
end
