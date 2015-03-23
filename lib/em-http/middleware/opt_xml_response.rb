require 'em-http/middleware/opt_response'
require 'nokogiri'

module EventMachine
  module Middleware
    class OptXMLResponse < OptResponse
      def make_value(resp)
        Nokogiri.XML(resp.response)
      end
    end
  end
end

