require 'pogoplug/service_client'

module PogoPlug
  class Service
    include HashInitializer

    attr_accessor :name, :id, :api_url, :online, :service_type, :raw, :token, :device_id, :logger

    def online?
      self.online
    end

    def client
      ServiceClient.new( token, api_url, device_id, id )
    end

    def self.from_json(json, token, logger)
      Service.new(
        name: json['name'],
        id: json['serviceid'],
        api_url: json['apiurl'],
        online: json['online'] == '1',
        service_type: json['type'],
        device_id: json['deviceid'],
        raw: json,
        token: token,
        logger: logger
      )
    end
  end
end
