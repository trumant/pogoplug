require 'faraday'
require 'faraday_middleware'
require 'faraday_curl'

module PogoPlug
  module HttpHelper

    def self.create( domain, logger = nil )
      Faraday.new(:url => domain) do |f|
        f.request :url_encoded
        if logger
          f.request :curl, logger, :warn
        end
        f.response :json, :content_type => /javascript|json/
        f.adapter Faraday.default_adapter
      end
    end

  end
end