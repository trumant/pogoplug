require 'spec_helper'
require 'pogoplug/device'

describe PogoPlug::Device do
  include TestFileUtils
  context "Device" do
    before do
      @name = "Pogoplug Cloud"
      @id = "XCLDGAAAHE5B5NKDKMUXJ52F9J"
      @device = PogoPlug::Device.new(name: @name, id: @id)
    end

    it "should provide a name" do
      expect(@device.name).to eq(@name)
    end

    it "should provide an ID" do
      expect(@device.id).to eq(@id)
    end

    it "should allow services to be added" do
      service = PogoPlug::Service.new(name: "some name", id: "some id")
      @device.services << service
      expect(@device.services.first).to eq(service)
    end

    it "should provide a collection of services" do
      expect(@device.services).to be_kind_of(Enumerable)
    end

    it "should be able to build instances from JSON" do
      json = contents_of("device_example.json")
      device = PogoPlug::Device.from_json(JSON.parse(json), "token", nil)
      expect(device.name).to eq("Pogoplug Cloud")
      expect(device.id).to eq("XCLDGAAAHE5B5NKDKMUXJ52F9J")
      expect(device.services.size).to eq(1)
    end
  end
end