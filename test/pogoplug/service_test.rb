require_relative 'helper'

class ServiceTest < Test::Unit::TestCase
  context "Service" do

    setup do
      @name = "Pogoplug Cloud"
      @id = "XCLDGAAAHE5B5NKDKMUXJ52F9J"
      @service = PogoPlug::Service.new(@name, @id)
    end

    should "provide an ID" do
      assert_equal(@service.id, @id)
    end

    should "provide a name" do
      assert_equal(@service.name, @name)
    end
  end
end
