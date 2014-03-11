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

    # Retrieve a list of files for a device and service
    def files(device_id, service_id, parent_id=nil, offset=0)
      params = { deviceid: device_id, serviceid: service_id, pageoffset: offset }
      params[:parentid] = parent_id unless parent_id.nil?

      response = get('/listFiles', params)
      FileListing.from_json(response.body)
    end

    # Retrieve a single file or directory
    def file(device_id, service_id, file_id)
      params = { deviceid: device_id, serviceid: service_id, fileid: file_id }
      response = get('/getFile', params)
      File.from_json(response.body['file'])
    end

    def create_directory(device_id, service_id, directory_name, parent_id=nil, properties = {})
      create_entity(device_id, service_id, File.create_directory(directory_name, parent_id), nil, properties)
    end

    def create_file(device_id, service_id, file_name, parent_id, io, properties = {} )
      create_entity(device_id, service_id, File.create_file(file_name, parent_id), io, properties)
    end

    # Creates a file handle and optionally attach an io.
    # The provided file argument is expected to contain at minimum
    # a name, type and parent_id. If it has a mimetype that will be assumed to
    # match the mimetype of the io.
    def create_entity(device_id, service_id, file, io=nil, properties = {})
      params = { deviceid: device_id, serviceid: service_id, filename: file.name, type: file.type }.merge(properties)
      params[:parentid] = file.parent_id unless file.parent_id.nil?
      response = get('/createFile', params)
      file_handle = File.from_json(response.body['file'])
      if io
        HttpHelper.send(files_url, @token, device_id, service_id, file_handle, io )
        file_handle.size = io.size
      end
      file_handle
    end

    def move(device_id, service_id, orig_file_name, file_id, parent_directory_id, file_name=nil)
      file_name ||= orig_file_name
      response = get('/moveFile', deviceid: device_id, serviceid: service_id,
        fileid: file_id, parentid: parent_directory_id, filename: file_name)
      File.from_json(response.body['file'])
    end

    def download(device_id, service, file)
      raise "Directories cannot be downloaded" unless file.file?
      open(URI.escape("#{service.api_url}files/#{@token}/#{device_id}/#{service.id}/#{file.id}/dl/#{file.name}")).read
    end

    def download_to(device_id, service_id, file, destination)
      raise "Directories cannot be downloaded" unless file.file?
      ::File.open(destination, "w") do |target|
        IO.copy_stream(
          open(URI.escape("#{files_url}/#{@token}/#{device_id}/#{service_id}/#{file.id}/dl/#{file.name}")),
          target
        )
      end
    end

    def delete(device_id, service_id, file_id)
      params = { deviceid: device_id, serviceid: service_id, fileid: file_id, recurse: '1' }
      response = get('/removeFile', params)
      true unless response.status.to_s != '200'
    end

    #returns the first file or directory that matches the given criteria
    def search_file(device_id, service_id, criteria)
      search(device_id, service_id, criteria)[0]
    end

    def search( device_id, service_id, criteria, options = {} )
      params = { deviceid: device_id, serviceid: service_id, searchcrit: criteria}.merge(options)
      response = get('/searchFiles', params)
      PogoPlug::FileListing.from_json(response.body)
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

    def files_url
      "#{api_domain}svc/files"
    end

    def validate_token
      if @token.nil?
        raise AuthenticationError('Authentication token is missing. Call login first.')
      end
    end

  end
end
