module PogoPlug
  class Service
    include HashInitializer

    attr_accessor :name, :id

    def self.from_json(json)
      Service.new(name: json['name'], id: json['serviceid'])
    end
  end
end
