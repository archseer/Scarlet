class String
  def word_wrap line_width = 80
    text = self
    return text if line_width <= 0
    text.split("\n").collect do |line|
      line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end

  def align width = 70, orientation = :left, padding=2
    text = self.strip
    if text.length < width
      margin = width-(text.length+padding*2) > 0 ? width-(text.length+padding*2) : 0
      if orientation == :right
        return text.rjust(margin).center(padding)
      elsif orientation == :left
        return text.ljust(margin).center(padding)
      elsif orientation == :center
        return text.center(width)
      end
    end
  end

  def irc_color fg, bg
    "\x03#{"%02d" % fg},#{"%02d" % bg}#{self}\x03"
  end
end