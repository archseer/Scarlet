require 'eventmachine'
require 'em-http-request'
# Optional responses
require 'em-http/middleware/opt_html_response'
require 'em-http/middleware/opt_json_response'
require 'em-http/middleware/opt_plaintext_response'
require 'em-http/middleware/opt_xml_response'

class Scarlet
  module HttpHelper
    # (see EventMachine::HttpRequest.new)
    def http_request *args, &block
      EM::HttpRequest.new *args, &block
    end

    def http_request_with_middleware middleware, *args, &block
      http_request(*args, &block).tap { |c| c.use middleware }
    end

    def plaintext_request *args, &block
      http_request_with_middleware EM::Middleware::OptPlaintextResponse, *args, &block
    end

    def html_request *args, &block
      http_request_with_middleware EM::Middleware::OptHTMLResponse, *args, &block
    end

    def json_request *args, &block
      http_request_with_middleware EM::Middleware::OptJSONResponse, *args, &block
    end

    def xml_request *args, &block
      http_request_with_middleware EM::Middleware::OptXMLResponse, *args, &block
    end
  end
end
