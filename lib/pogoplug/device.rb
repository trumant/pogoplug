module PogoPlug
  class Device
    include HashInitializer

    attr_accessor :name, :id, :services

    def services
      @services ||= Array.new
    end

    def self.from_json(json)
      device = Device.new(name: json['name'], id: json['deviceid'])
      json['services'].each do |s|
        device.services << Service.from_json(s)
      end
      device
    end
  end
end
