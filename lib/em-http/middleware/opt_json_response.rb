require 'em-http/middleware/opt_response'
require 'multi_json'

module EventMachine
  module Middleware
    class OptJSONResponse < OptResponse
      def make_value resp
        MultiJson.load resp.response
      end
    end
  end
end
