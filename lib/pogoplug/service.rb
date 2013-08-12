module PogoPlug
  class Service
    attr_accessor :name, :id

    def initialize(name, id)
      @name = name
      @id = id
    end
  end
end
