require 'em-http/middleware/opt_response'

module EventMachine
  module Middleware
    class OptPlaintextResponse < OptResponse
      class NotPlaintext < TypeError
      end

      def make_value resp
        resp.response
      end
    end
  end
end
