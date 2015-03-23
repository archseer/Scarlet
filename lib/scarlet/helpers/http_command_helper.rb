require 'eventmachine'
require 'em-http'
require 'em-http/middleware/json_response'
require 'scarlet/em-http/middleware/xml_response'

module Scarlet
  module HttpCommandHelper
    # (see EventMachine::HttpRequest.new)
    def self.http_request *args, &block
      EM::HttpRequest.new *args, &block
    end

    def self.json_request *args, &block
      http_request(*args, &block).tap { |c| c.use EM::Middleware::JSONResponse }
    end

    def self.xml_request *args, &block
      http_request(*args, &block).tap { |c| c.use EM::Middleware::XMLResponse }
    end
  end
end
