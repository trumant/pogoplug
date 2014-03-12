module PogoPlug
  class AuthenticationError < StandardError
  end

  class DuplicateNameError < StandardError
  end

  class NotFoundError < StandardError
  end

  ApiUrlNotAvailable = Class.new(StandardError)
  DirectoriesCanNotBeDownloaded = Class.new(StandardError)

  class ServiceError < StandardError
    attr_reader :response
    def initialize( response )
      super("Failed to process request #{response.status} - #{response.headers.inspect} - #{response.body}")
      @response = response
    end
  end
end