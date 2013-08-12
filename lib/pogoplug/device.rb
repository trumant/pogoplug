module PogoPlug
  class Device
    attr_accessor :name, :id, :services

    def initialize(name, id)
      @name = name
      @id = id
      @services = []
    end

    def self.from_json(json)
      device = Device.new(json['name'], json['deviceid'])
      json['services'].each do |s|
        device.services << Service.from_json(s)
      end
      device
    end
  end
end
