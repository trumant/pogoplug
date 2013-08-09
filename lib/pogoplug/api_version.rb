module PogoPlug
  class ApiVersion
    attr_accessor :version, :build_date

    def initialize(version, build_date)
      @version = version
      @build_date = build_date
    end
  end
end
