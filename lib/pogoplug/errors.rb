module PogoPlug
  class AuthenticationError < StandardError
  end

  class DuplicateNameError < StandardError
  end

  class NotFoundError < StandardError
  end

  class ServiceError < StandardError
    attr_reader :response
    def initialize( response )
      super("Failed to process request #{response.code} - #{response.headers.inspect} - #{response.body}")
      @response = response
    end
  end
end