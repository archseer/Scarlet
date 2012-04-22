module IrcBot
  class InfoTable
    attr_accessor :colors, :width, :padding
    COLOR_SET = {
      "content" => 0,
      "header"  => 1,
      "warning" => 2
    }
    def initialize(width)
      @width     = width
      @padding   = 0
      @colors    = {}
      @colors[0] = [1,0] # // Content
      @colors[1] = [0,1] # // Header
      @colors[2] = [1,8] # // Warning
      @lines     = []
      @headers   = []
    end
    def clear()
      clear_lines()
      clear_headers()
      self
    end
    def clear_headers()
      @headers.clear()
      self
    end
    def clear_lines()
      @lines.clear()
      self
    end
    def addHeader(string)
      @headers << string
    end  
    def addRow(string)
      @lines << string
      self
    end
    def compile()
      @headers.collect{|s|s.align(@width,:center,@padding).irc_color(*@colors[1])} +
      @lines.collect{|s|s.align(@width,:left,@padding).irc_color(*@colors[0])}
    end
  end
end