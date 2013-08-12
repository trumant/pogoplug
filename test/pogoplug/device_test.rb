require_relative 'helper'

module PogoPlug
  class DeviceTest < Test::Unit::TestCase
    context "Device" do
      setup do
        @name = "Pogoplug Cloud"
        @id = "XCLDGAAAHE5B5NKDKMUXJ52F9J"
        @device = PogoPlug::Device.new(@name, @id)
      end

      should "provide a name" do
        assert_equal(@device.name, @name)
      end

      should "provide an ID" do
        assert_equal(@device.id, @id)
      end

      should "allow services to be added" do
        service = PogoPlug::Service.new("some name", "some id")
        @device.services << service
        assert_equal(@device.services.first, service)
      end

      should "provide a collection of services" do
        assert_kind_of(Enumerable, @device.services)
      end
    end
  end
end
