require 'em-http'
require 'nokogiri'

module EventMachine
  module Middleware
    class XMLResponse
      def response(resp)
        body = Nokogiri.XML(resp.response)
        resp.response = body
      rescue => ex
        puts ex.inspect
      end
    end
  end
end

