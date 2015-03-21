require 'eventmachine'
require 'em-http-request'

module Scarlet
  module HttpCommandHelper
    def http_request(url)
      EventMachine::HttpRequest.new(url)
    end
  end
end
