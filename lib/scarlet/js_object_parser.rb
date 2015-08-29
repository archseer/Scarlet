require 'strscan'

class Scarlet
  # NO, NOT JSON, JS (Javascript), because google just had to screw us over.
  # A very very obscure parser, don't try this at home
  class JsObjectParser
    class ParserJam < RuntimeError
    end

    # Called when the parser can't continue, or encountered some weird stuff
    #
    # @param [StringScanner] ptr
    def parser_jam ptr
      raise ParserJam, "parser has jammed at #{ptr.pos}/#{ptr.string.size}, rest: #{ptr.rest}"
    end

    # @param [StringScanner] ptr
    # @return [String] spaaaaace
    def skip_spaces ptr
      ptr.scan(/[\s\t\n]+/)
    end

    # @param [StringScanner] ptr
    # @return [String] string
    def parse_string ptr
      ptr.scan_until(/"/).chop
    end

    # @param [StringScanner] ptr
    # @return [Hash<String, Object>]
    def parse_object ptr
      obj = {}
      loop do
        skip_spaces(ptr)
        break if ptr.scan(/\}/)
        key = ptr.scan(/[a-zA-Z]\w*:/).chop
        parser_jam ptr unless key
        value = parse_content(ptr)
        obj[key] = value
        ptr.scan(/\s*,/)
        parser_jam ptr if ptr.eos?
      end
      obj
    end

    # @param [StringScanner] ptr
    # @return [Array]
    def parse_array ptr
      obj = []
      loop do
        skip_spaces(ptr)
        break if ptr.scan(/\]/)
        obj << parse_content(ptr)
        ptr.scan(/\s*,/)
        parser_jam ptr if ptr.eos?
      end
      obj
    end

    # @param [StringScanner] ptr
    # @return [Object]
    def parse_content ptr
      skip_spaces(ptr)
      if ptr.scan(/\[/)
        parse_array(ptr)
      elsif ptr.scan(/"/)
        parse_string(ptr)
      elsif ptr.scan(/\{/)
        parse_object(ptr)
      elsif str = ptr.scan(/true|false|null/)
        case str
        when 'true'
          true
        when 'false'
          false
        when 'null'
          nil
        end
      elsif flt = ptr.scan(/\d+\.\d+/)
        flt.to_f
      elsif int = ptr.scan(/\d+/)
        int.to_i
      elsif ptr.peek(1) == ','
        nil
      else
        parser_jam ptr
      end
    end

    # @param [String] str
    # @return [Object]
    def parse str
      parse_content(StringScanner.new(str))
    end

    def self.parse(str)
      new.parse(str)
    end
  end
end
