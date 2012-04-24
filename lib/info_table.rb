#=========================================#
# // Date Created : 04/07/2012
# // Date Modified: 04/23/2012
# // Created by IceDragon (IceDragon200)
#=========================================#
module IrcBot
  class ColumnTable
    VERSION = 0.0001
    class Column
      VERSION = 0.0001
      attr_accessor :width
      def initialize(width=50)
        @width  = width
        @lines  = []
      end
      def autoWidth
        @width = @rows.max_by(){|str|str.size}.size
        @width += (@width % 2) + 2
        self
      end  
      def clearType(type)
        @lines.select!{|a|a[0]!=(type)}
        self
      end
      def clear()
        @lines.clear()
        self
      end
      def addLine(type,str,colors)
        @lines << [type,str,colors]
        self
      end
      def addRow(str="",colors=[1,0])
        addLine(:line,str,colors)
      end
      def addHeader(str="",colors=[0,1])
        addLine(:header,str,colors)
      end
      def addSpace()
        addLine(:space,"",[0,0])
      end
      # // type isnt actually used here.
      # // Its used however for searching, sorting
      def compile_a()
        type,str,cus_color = [nil]*3
        @lines.collect do |row_a|
          type,str,cus_color = row_a
          str.align(@width).irc_color(*cus_color)
        end
      end
      def size()
        @lines.size
      end
    end    
    def initialize()
      @columns = []
      @line = 0
      @row_override = {}
    end
    def clear()
      @columns.clear()
      self
    end
    def addColumn()
      @columns << Column.new
      self
    end
    def column(index)
      @columns[index]
    end
    # // String[] args
    def addHeader(*args)
      @columns.each_with_index{|c,i|c.addHeader(args[i])}
      self
    end
    def addRow(*args)
      @columns.each_with_index{|c,i|c.addRow(args[i])}
      self
    end
    def addSpace()
      @columns.each{|c|c.addSpace()}
    end
    def calc_line()
      @line = @columns.max_by{|c|c.size}
    end  
    def compile()
      col_a = @columns.collect{|c|c.autoWidth().compile_a()}
      tw = @columns.inject(0){|r,c|r+c.width}
      @row_override.values.eac{|v|v[0]=tw}
      rows_c= col_a.max_by(){|a|a.size}
      (0...rows_c).collect do |i|
        row_override(i) || col_a.inject(""){|r,c|r+c[i]}
      end
    end
    def addRowO(str,colors=[0,1])
      @row_override[calc_line()] = [str.size,str,colors]
    end
    def row_override(index)
      return nil unless(@row_override.has_key?(index))
      width,str,colors = @row_override[index]
      str.align(width,:center).irc_color(*colors)
    end
    # // A simple 3 column table
    def self.test()
      col_table = new()
      col_table.clear()
      3.times{col_table.addColumn()}
      col_table.addHeader("Speed", "IceDragon", "Crimson")
      col_table.addRowO("Stuff we like",[1,11])
      col_table.addRow("Hip-Hop", "Cookies", "Moka~")
      col_table.addRowO("More stuff",[1,11])
      col_table.addRow("Art", "Moar Cookies", "Anime")
      col_table.addRowO("End of stuff",[1,0])
      col_table.compile
    end
  end  
  class InfoTable
    VERSION = 0.0002
    attr_accessor :colors, :width, :padding
    def initialize(width=50)
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
#=■==========================================================================■=#
#                           // ● End of File ● //                              #
#=■==========================================================================■=#