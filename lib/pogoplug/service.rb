module PogoPlug
  class Service
    include HashInitializer

    attr_accessor :name, :id, :api_url, :online, :service_type, :raw

    def online?
      self.online
    end

    def self.from_json(json)
      Service.new(
        name: json['name'],
        id: json['serviceid'],
        api_url: json['apiurl'],
        online: json['online'] == '1',
        service_type: json['type'],
        raw: json
      )
    end
  end
end
