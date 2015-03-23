require 'em-http'

module EventMachine
  module Middleware
    class OptResponse
      class Option
        # original data before make_value
        attr_accessor :data
        # transformed data
        attr_accessor :value
        # error in case transformation failed
        attr_accessor :err
      end

      def make_value resp
        resp.response
      end

      def response resp
        opt = Option.new
        opt.data = resp.response
        begin
          opt.value = make_value resp
        rescue Exception => ex
          opt.err = ex.dup
        end
        resp.response = opt
      end
    end
  end
end
