require 'httparty'
require 'json'

module PogoPlug
  class Client
    include HTTParty
    # debug_output $stdout
    base_uri 'https://service.pogoplug.com/svc/api/json'
    format :json

    # Retrieve the current version information of the service
    def version
      response = self.class.get('/getVersion')
      json = JSON.parse(response.body)
      ApiVersion.new(json['version'], json['builddate'])
    end

    # Retrieve an auth token that can be used to make additional calls
    # * *Raises* :
    #   - +AuthenticationError+ -> if PogoPlug does not like the credentials you provided
    def login(email, password)
      response = self.class.get('/loginUser', query: { email: email, password: password })
      raise_errors(response)
      response.parsed_response["valtoken"]
    end

    # Retrieve a list of devices that are registered with the PogoPlug account
    def devices(token)
      response = self.class.get('/listDevices', query: { valtoken: token })
      devices = []
      response.parsed_response['devices'].each do |d|
        devices << Device.from_json(d)
      end
      devices
    end

    # Retrieve a list of services
    def services(token, device_id=nil, shared=false)
      params = { valtoken: token, shared: shared }
      params[:deviceid] = device_id unless device_id.nil?

      response = self.class.get('/listServices', query: params)
      services = []
      response.parsed_response['services'].each do |s|
        services << Service.from_json(s)
      end
      services
    end

    # Retrieve a list of files for a device and service
    def files(token, device_id, service_id, offset=0)
      params = { valtoken: token, deviceid: device_id, serviceid: service_id, pageoffset: offset }
      response = self.class.get('/listFiles', query: params)
      FileListing.from_json(response.parsed_response)
    end

    def create_directory(token, device_id, service_id, directory_name, parent_id=nil)
      create_file(token, device_id, service_id, File.new(name: directory_name, parent_id: parent_id, type: File::Type::DIRECTORY))
    end

    def create_file(token, device_id, service, file, io=nil)
      params = { valtoken: token, deviceid: device_id, serviceid: service.id, filename: file.name, type: file.type }
      params[:parentid] = file.parent_id unless file.parent_id.nil?
      response = self.class.get('/createFile', query: params)
      file_handle = File.from_json(response.parsed_response['file'])
      if io
        uri = URI.parse("#{service.api_url}files/#{token}/#{device_id}/#{service.id}/#{file_handle.id}/#{::File.basename(io.path)}")
        # puts uri.inspect
        req = Net::HTTP::Put.new(uri.path)
        req['Content-Length'] = io.size
        req['Content-Type'] = file.mimetype
        req.body_stream = io
        # puts req.to_hash.inspect
        put_response = Net::HTTP.new(uri.host, uri.port).request(req)
        puts put_response.inspect
        puts put_response.body
      end
      # puts file_handle.inspect
      file_handle
    end

    private

    def raise_errors(response)
      if response.parsed_response['HB-EXCEPTION'] && response.parsed_response['HB-EXCEPTION']['ecode'] == 606
        raise AuthenticationError
      end
    end
  end
end
