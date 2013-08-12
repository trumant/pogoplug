module PogoPlug
  class Service
    attr_accessor :name, :id

    def initialize(name, id)
      @name = name
      @id = id
    end

    def self.from_json(json)
      Service.new(json['name'], json['serviceid'])
    end
  end
end
