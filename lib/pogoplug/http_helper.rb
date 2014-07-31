require 'faraday'
require 'faraday_middleware'
require 'faraday_curl'
require 'pogoplug/errors'

module PogoPlug
  module HttpHelper

    class HttpError < StandardError

      attr_reader :original

      def initialize(original)
        @original = original
        super(to_message)
      end

      def to_message
        case @original
          when Net::HTTPClientError, Net::HTTPServerError
            "#{@original.inspect} - #{@original.body} - #{@original.to_hash.inspect}"
          else
            @original.inspect
        end
      end

    end

    def self.create(domain, logger = nil)
      Faraday.new(:url => domain) do |f|
        f.request :url_encoded
        if logger
          f.request :curl, logger, :warn
        end
        f.request :retry, max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2
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

    def self.send_file(files_url, token, device_id, service_id, file_handle, io, logger = nil)
      uri = URI.parse("#{files_url}/#{token}/#{device_id}/#{service_id}/#{file_handle.id}")
      req = Net::HTTP::Put.new(uri.path)
      req['Content-Length'] = io.size
      req['Content-Type'] = file_handle.mimetype

      logger_block = lambda do |message|
        logger.info(message) if logger
      end

      logger_block.call("Uploading #{file_handle.inspect} to #{uri} - #{io.size} bytes")

      req.body_stream = io
      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = true if uri.scheme == "https"
      response = client.request(req)

      case response
        when Net::HTTPSuccess
          logger_block.call("Successfully uploaded file #{response.inspect} - #{response.body}")
        else
          logger_block.call("Failed to process request - #{response.inspect}")
          raise HttpError.new(response)
      end

      response
    end

  end
end