require 'open-uri'
require 'pogoplug/http_helper'

module PogoPlug
  class Client

    attr_accessor :token, :api_domain, :logger

    def initialize( api_domain = "https://service.pogoplug.com/", logger = nil )
      @api_domain = api_domain
      @logger = logger
    end

    # Retrieve the current version information of the service
    def version
      response = get('/getVersion', {}, false )
      ApiVersion.new(response.body['version'], response.body['builddate'])
    end

    # Retrieve an auth token that can be used to make additional calls
    # * *Raises* :
    #   - +AuthenticationError+ -> if PogoPlug does not like the credentials you provided
    def login(email, password)
      response = get('/loginUser', {email: email, password: password }, false)
      @token = response.body["valtoken"]
    end

    # Retrieve a list of devices that are registered with the PogoPlug account
    def devices
      response = get('/listDevices')
      devices = []
      response.body['devices'].each do |d|
        devices << Device.from_json(d, @token, @logger)
      end
      devices
    end

    def online_devices
      devices.select do |device|
        device.services.find { |service| service.online? }
      end
    end

    # Retrieve a list of services
    def services(device_id=nil, shared=false)
      params = { shared: shared }
      params[:deviceid] = device_id unless device_id.nil?

      response = get('/listServices', params)
      services = []
      response.body['services'].each do |s|
        services << Service.from_json(s, @token, @logger)
      end
      services
    end

    private

    def get( url, params = {}, should_validate_token = true )
      validate_token if should_validate_token

      headers = {}
      if @token
        headers["cookie"] = "valtoken=#{@token}"
      end

      response = ::PogoPlug::HttpHelper.create(@api_domain, @logger).get("svc/api#{url}", params, headers)
      ::PogoPlug::HttpHelper.raise_errors(response)

      response
    end

    def validate_token
      if @token.nil?
        raise AuthenticationError('Authentication token is missing. Call login first.')
      end
    end

  end
end
