require 'yajl'

class Scarlet
  module JsonCommandHelper
    def self.parse_json str
      Yajl::Parser.parse str
    end
  end
end
