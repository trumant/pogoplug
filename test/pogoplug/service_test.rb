require_relative 'helper'

module PogoPlug
  class ServiceTest < Test::Unit::TestCase
    context "Service" do

      setup do
        @name = "Pogoplug Cloud"
        @id = "XCLDGAAAHE5B5NKDKMUXJ52F9J"
        @service = PogoPlug::Service.new(name: @name, id: @id)
      end

      should "provide an ID" do
        assert_equal(@service.id, @id)
      end

      should "provide a name" do
        assert_equal(@service.name, @name)
      end

      should "be able to build instances from JSON" do
        json = %q{
          {
            "deviceid": "XCLDGAAAHE5B5NKDKMUXJ52F9J",
            "serviceid": "XCLDGAAAHE5B5NKDKMUXJ52F9J",
            "sclass": "1",
            "type": "xce:plugfs:cloud",
            "name": "Pogoplug Cloud",
            "version": "4.6.0.12",
            "online": "1",
            "msgpending": "0",
            "apiurl": "https://cl0c0.pogoplug.com/svc/api/",
            "space": "5000000000/5000000000",
            "flags": "0",
            "onlan": "0",
            "metaver": "0"
          }
        }
        service = Service.from_json(JSON.parse(json))
        assert_equal(service.id, "XCLDGAAAHE5B5NKDKMUXJ52F9J")
        assert_equal(service.name, "Pogoplug Cloud")
      end
    end
  end
end
