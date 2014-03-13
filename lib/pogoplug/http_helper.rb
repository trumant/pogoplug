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
        yield(f) if block_given?
        f.response :json, :content_type => /javascript|json/
        f.adapter Faraday.default_adapter
      end
    end

    def self.raise_errors(response)
      error_code = response.body['HB-EXCEPTION']['ecode'] if response.body['HB-EXCEPTION']

      if exception = PogoPlug::ERRORS[error_code]
        raise exception.new(response)
      elsif !response.success?
        raise ServerError.new(response)
      end
    end

    def self.send_file( files_url, token, device_id, service_id, file_handle, io)
      uri = URI.parse("#{files_url}/#{token}/#{device_id}/#{service_id}/#{file_handle.id}")
      req = Net::HTTP::Put.new(uri.path)
      req['Content-Length'] = io.size
      req['Content-Type'] = file_handle.mimetype
      req.body_stream = io
      Net::HTTP.new(uri.host, uri.port).request(req)
    end

  end
end