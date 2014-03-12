require 'spec_helper'
require 'pogoplug/service'

describe PogoPlug::Service do

  it "should provide an ID and a name" do
    @name = "Pogoplug Cloud"
    @id = "XCLDGAAAHE5B5NKDKMUXJ52F9J"
    @service = PogoPlug::Service.new(name: @name, id: @id)

    expect(@service.id).to eq(@id)
    expect(@service.name).to eq(@name)
  end

  it "should be able to build instances from JSON" do
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
    service = PogoPlug::Service.from_json(JSON.parse(json), "token", nil)
    expect(service.id).to eq("XCLDGAAAHE5B5NKDKMUXJ52F9J")
    expect(service.name).to eq("Pogoplug Cloud")
    expect(service.api_url).to eq("https://cl0c0.pogoplug.com/svc/api/")
  end

end

