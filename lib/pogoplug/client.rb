require 'httparty'
require 'json'
require 'open-uri'

module PogoPlug
  class Client
    include HTTParty
    format :json
    attr_accessor :token, :api_domain

    def initialize(api_domain="https://service.pogoplug.com/", debug_logging=false)
      @api_domain = api_domain
      self.class.base_uri "#{api_domain}svc/api/json"
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
    def files(device_id, service_id, parent_id=nil, offset=0)
      params = { valtoken: @token, deviceid: device_id, serviceid: service_id, pageoffset: offset }
      params[:parentid] = parent_id unless parent_id.nil?

      response = self.class.get('/listFiles', query: params)
      FileListing.from_json(response.parsed_response)
    end

    # Retrieve a single file or directory
    def file(device_id, service_id, file_id)
      params = { valtoken: @token, deviceid: device_id, serviceid: service_id, fileid: file_id }
      response = self.class.get('/getFile', query: params)
      raise_errors(response)
      File.from_json(response.parsed_response['file'])
    end

    def create_directory(device_id, service_id, directory_name, parent_id=nil)
      create_entity(device_id, service_id, File.new(name: directory_name, parent_id: parent_id, type: File::Type::DIRECTORY))
    end

    def create_file(device_id, service_id, file_name, parent_id, io=nil)
      create_entity(device_id, service_id, File.new(name: file_name, parent_id: parent_id, type: File::Type::FILE), io)
    end

    # Creates a file handle and optionally attach an io.
    # The provided file argument is expected to contain at minimum
    # a name, type and parent_id. If it has a mimetype that will be assumed to
    # match the mimetype of the io.
    def create_entity(device_id, service_id, file, io=nil)
      params = { valtoken: @token, deviceid: device_id, serviceid: service_id, filename: file.name, type: file.type }
      params[:parentid] = file.parent_id unless file.parent_id.nil?
      response = self.class.get('/createFile', query: params)
      raise_errors(response)
      file_handle = File.from_json(response.parsed_response['file'])
      if io
        send_file(device_id, service_id, file_handle, io)
        file_handle.size = io.size
      end
      file_handle
    end

    def move(device_id, service_id, orig_file_name, file_id, parent_directory_id, file_name=nil)
      file_name ||= orig_file_name
      response = self.class.get('/moveFile', query: {
        valtoken: @token, deviceid: device_id, serviceid: service_id,
        fileid: file_id, parentid: parent_directory_id, filename: file_name })
      raise_errors(response)
      File.from_json(response.parsed_response['file'])
    end

    def download(device_id, service, file)
      raise "Directories cannot be downloaded" unless file.file?
      open(URI.escape("#{service.api_url}files/#{@token}/#{device_id}/#{service.id}/#{file.id}/dl/#{file.name}")).read
    end

    def download_to(device_id, service_id, file, destination)
      raise "Directories cannot be downloaded" unless file.file?
      target = ::File.open(destination, "w")
      begin
        IO.copy_stream(
          open(URI.escape("#{files_url}/#{@token}/#{device_id}/#{service_id}/#{file.id}/dl/#{file.name}")),
          target
        )
      ensure
        target.close
      end
      target
    end

    def delete(device_id, service_id, file_id)
      params = { valtoken: @token, deviceid: device_id, serviceid: service_id, fileid: file_id, recurse: '1' }
      response = self.class.get('/removeFile', query: params)
      true unless response.code.to_s != '200'
    end

    #returns the first file or directory that matches the given criteria
    def search_file(device_id, service_id, criteria)
      params = { valtoken: @token, deviceid: device_id, serviceid: service_id, searchcrit: criteria}
      response = self.class.get('/searchFiles', query: params)
      raise_errors(response)
      File.from_json(response.parsed_response['files'][0])
    end

    private

    def files_url
      "#{api_domain}svc/files"
    end

    def validate_token
      if @token.nil?
        raise AuthenticationError('Authentication token is missing. Call login first.')
      end
    end

    def raise_errors(response)
      error_code = response.parsed_response['HB-EXCEPTION']['ecode'] if response.parsed_response['HB-EXCEPTION']
      case error_code
      when 606
        raise AuthenticationError
      when 808
        raise DuplicateNameError
      when 804
        raise NotFoundError
      else
      end
    end

    def send_file(device_id, service_id, file_handle, io)
      parent = file_handle.id || 0
      uri = URI.parse("#{files_url}/#{@token}/#{device_id}/#{service_id}/#{parent}/#{file_handle.name}")
      req = Net::HTTP::Put.new(uri.path)
      req['Content-Length'] = io.size
      req['Content-Type'] = file_handle.mimetype
      req.body_stream = io
      Net::HTTP.new(uri.host, uri.port).request(req)
    end
  end
end
