require 'httparty'
require 'json'
require 'open-uri'

module PogoPlug
  class Client
    include HTTParty
    format :json
    attr_accessor :token

    def initialize(base_uri="https://service.pogoplug.com/svc/api/json", debug_logging=false)
      self.class.base_uri base_uri
      if debug_logging
        self.class.debug_output $stdout
      end
    end

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
      @token = response.parsed_response["valtoken"]
      return self
    end

    # Retrieve a list of devices that are registered with the PogoPlug account
    def devices
      validate_token
      response = self.class.get('/listDevices', query: { valtoken: @token })
      devices = []
      response.parsed_response['devices'].each do |d|
        devices << Device.from_json(d)
      end
      devices
    end

    # Retrieve a list of services
    def services(device_id=nil, shared=false)
      validate_token
      params = { valtoken: @token, shared: shared }
      params[:deviceid] = device_id unless device_id.nil?

      response = self.class.get('/listServices', query: params)
      services = []
      response.parsed_response['services'].each do |s|
        services << Service.from_json(s)
      end
      services
    end

    # Retrieve a list of files for a device and service
    def files(device_id, service_id, offset=0)
      params = { valtoken: @token, deviceid: device_id, serviceid: service_id, pageoffset: offset }
      response = self.class.get('/listFiles', query: params)
      FileListing.from_json(response.parsed_response)
    end

    def create_directory(device_id, service_id, directory_name, parent_id=nil)
      create_file(device_id, service_id, File.new(name: directory_name, parent_id: parent_id, type: File::Type::DIRECTORY))
    end

    # Creates a file handle and optionally attach an io.
    # The provided file argument is expected to contain at minimum
    # a name, type and parent_id. If it has a mimetype that will be assumed to
    # match the mimetype of the io.
    def create_file(device_id, service, file, io=nil)
      params = { valtoken: @token, deviceid: device_id, serviceid: service.id, filename: file.name, type: file.type }
      params[:parentid] = file.parent_id unless file.parent_id.nil?
      response = self.class.get('/createFile', query: params)
      file_handle = File.from_json(response.parsed_response['file'])
      if io
        send_file(device_id, service, file_handle, io)
        file_handle.size = io.size
      end
      file_handle
    end

    def move(device_id, service_id, file, parent_directory_id)
      response = self.class.get('/moveFile', query: {
        valtoken: @token, deviceid: device_id, serviceid: service_id,
        fileid: file.id, parentid: parent_directory_id })
      true unless response.code.to_s != '200'
    end

    def download(device_id, service, file)
      raise "Directories cannot be downloaded" unless file.file?
      open(URI.escape("#{service.api_url}files/#{@token}/#{device_id}/#{service.id}/#{file.id}/dl/#{file.name}")).read
    end

    def delete(device_id, service_id, file)
      params = { valtoken: @token, deviceid: device_id, serviceid: service_id, fileid: file.id }
      response = self.class.get('/removeFile', query: params)
      true unless response.code.to_s != '200'
    end

    private

    def validate_token
      if @token.nil?
        raise AuthenticationError('Authentication token is missing. Call login first.')
      end
    end

    def raise_errors(response)
      if response.parsed_response['HB-EXCEPTION'] && response.parsed_response['HB-EXCEPTION']['ecode'] == 606
        raise AuthenticationError
      end
    end

    def send_file(device_id, service, file_handle, io)
      parent = file_handle.id || 0
      uri = URI.parse("#{service.api_url}files/#{@token}/#{device_id}/#{service.id}/#{parent}/#{file_handle.name}")
      req = Net::HTTP::Put.new(uri.path)
      req['Content-Length'] = io.size
      req['Content-Type'] = file_handle.mimetype
      req.body_stream = io
      put_response = Net::HTTP.new(uri.host, uri.port).request(req)
    end
  end
end
