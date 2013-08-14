module PogoPlug
  module HashInitializer
    def initialize(*h)
      if h.length == 1 && h.first.kind_of?(Hash)
        h.first.each { |k,v| send("#{k}=",v) }
      end
    end
  end
end
