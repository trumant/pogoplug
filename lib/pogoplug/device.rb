module PogoPlug
  class Device
    attr_accessor :name, :id, :services

    def initialize(name, id)
      @name = name
      @id = id
      @services = []
    end
  end
end
