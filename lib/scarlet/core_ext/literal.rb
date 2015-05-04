# Alias module for String and Symbols
module Literal
end

class String
  include Literal
end

class Symbol
  include Literal
end
