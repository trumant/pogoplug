module PogoPlug
  class Service
    include HashInitializer

    attr_accessor :name, :id, :api_url

    def self.from_json(json)
      Service.new(name: json['name'], id: json['serviceid'], api_url: json['apiurl'])
    end
  end
end
