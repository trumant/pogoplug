require 'open-uri'
require 'pogoplug/http_helper'

module PogoPlug
  class Client

    attr_accessor :token, :api_domain, :logger, :client_id, :shared_secret

    def initialize(api_domain = "https://service.pogoplug.com/", logger = nil)
      @api_domain = api_domain
      @logger = logger
      yield(self) if block_given?
    end

    # Retrieve the current version information of the service
    def version
      response = get('/getVersion', {}, false)
      ApiVersion.new(response.body['version'], response.body['builddate'])
    end

    # Retrieve an auth token that can be used to make additional calls
    # * *Raises* :
    #   - +AuthenticationError+ -> if PogoPlug does not like the credentials you provided
    def login(email, password)
      response = get('/loginUser', { email: email, password: password }, false)
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

    def redirect_url(callback_url)
      query = {
        :client_id => self.client_id,
        :response_type => 'code',
        #:redirect_uri => callback_url # doesn't work because the api doesn't understand URL encoded params
      }.map do |key, value|
        value.to_query(key)
      end * '&'

      query << "&redirect_uri=#{callback_url}"

      build_uri("/oauth", query)
    end

    def get_access_token(access_code)
      body = "redirect_uri=https://127.0.0.1&grant_type=authorization_code&code=#{access_code}" # yes, no URL encoding or it fails

      request = ::PogoPlug::HttpHelper.create(@api_domain, @logger) do |f|
        f.request :basic_auth, @client_id, @shared_secret
      end

      response = request.get("oauth/token", body)
      ::PogoPlug::HttpHelper.raise_errors(response)

      token_response.parsed_response["access_token"]
    end

    def user_data
      get('/getUser').body
    end

    private

    def get(url, params = {}, should_validate_token = true)
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

    def uri
      @uri ||= URI(@api_domain)
    end

    def build_uri(path, query_params = nil)
      result = {
        :host => uri.host,
        :path => path
      }

      case query_params
        when Hash
          result[:query] = query_params.to_query
        when String
          result[:query] = query_params
      end

      case uri.scheme
        when 'https'
          URI::HTTPS
        else
          URI::HTTP
      end.build(result).to_s
    end

  end
end
