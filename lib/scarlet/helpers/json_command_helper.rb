require 'yajl'

module Scarlet
  module JsonCommandHelper
    def parse_json str
      Yajl::Parser.parse str
    end
  end
end
