require 'pogoplug/hash_initializer'
require 'pogoplug/service'

module PogoPlug
  class Device
    include HashInitializer

    attr_accessor :name, :id, :services, :device_type, :raw, :token

    def services
      @services ||= Array.new
    end

    def self.from_json(json, token, logger)
      device = Device.new(name: json['name'], id: json['deviceid'], device_type: json['type'], raw: json, token: token)
      json['services'].each do |s|
        device.services << Service.from_json(s, token, logger)
      end
      device
    end
  end
end
