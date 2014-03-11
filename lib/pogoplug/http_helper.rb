require 'faraday'
require 'faraday_middleware'
require 'faraday_curl'
require 'pogoplug/errors'

module PogoPlug
  module HttpHelper

    def self.create(domain, logger = nil)
      Faraday.new(:url => domain) do |f|
        f.request :url_encoded
        if logger
          f.request :curl, logger, :warn
        end
        f.response :json, :content_type => /javascript|json/
        f.adapter Faraday.default_adapter
      end
    end

    def self.raise_errors(response)
      error_code = response.body['HB-EXCEPTION']['ecode'] if response.body['HB-EXCEPTION']
      case error_code
        when 606
          raise AuthenticationError
        when 808
          raise DuplicateNameError
        when 804
          raise NotFoundError
        else
          unless response.success?
            raise ServiceError.new(response)
          end
      end
    end

    def self.send_file( files_url, token, device_id, service_id, file_handle, io)
      parent = file_handle.id || 0
      uri = URI.parse("#{files_url}/#{token}/#{device_id}/#{service_id}/#{parent}/#{file_handle.name}")
      req = Net::HTTP::Put.new(uri.path)
      req['Content-Length'] = io.size
      req['Content-Type'] = file_handle.mimetype
      req.body_stream = io
      Net::HTTP.new(uri.host, uri.port).request(req)
    end

  end
end