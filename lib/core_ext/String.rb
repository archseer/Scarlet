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
        return " " * (padding + margin) + text + (" " * padding)
      elsif orientation == :left
        return (" " * padding) + text  + " " * (margin + padding)
      elsif orientation == :center
        left_margin = (width - l)/2
        right_margin = width - l - left_margin
        return (" " * left_margin) + text + (" " * right_margin)
      end
    end
  end

  def irc_color fg, bg
    "\x03#{"%02d" % fg},#{"%02d" % bg}#{self}\x03"
  end
end