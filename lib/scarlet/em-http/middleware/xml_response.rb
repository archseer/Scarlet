require 'em-http'
require 'nokogiri'

module EventMachine
  module Middleware
    module XMLResponse
      def response(resp)
        body = Nokogiri.XML(resp)
        resp.response = body
      rescue => ex
      end
    end
  end
end

