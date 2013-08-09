require 'httparty'

module PogoPlug
  class Client
    include HTTParty
    debug_output $stdout
    base_uri 'https://service.pogoplug.com/svc/api/json'

    # Retrieve the current version information of the service
    def version
      response = self.class.get('/getVersion')
      ApiVersion.new(response.parsed_response['version'], response.parsed_response['builddate'])
    end

    # Retrieve an auth token that can be used to make additional calls
    def login(email, password)
      response = self.class.get('/loginUser', query: { email: email, password: password })
      puts response.inspect
      response.parsed_response['valtoken']
    end
  end
end
