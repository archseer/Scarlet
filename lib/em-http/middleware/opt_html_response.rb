require 'em-http/middleware/opt_response'
require 'nokogiri'

module EventMachine
  module Middleware
    class OptHTMLResponse < OptResponse
      def make_value resp
        Nokogiri.HTML resp.response
      end
    end
  end
end
