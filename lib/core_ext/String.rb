class String
  # Word wraps the string to the specified length.
  def word_wrap line_width = 80
    self.gsub(/(.{1,#{line_width}})(\s+|\Z)/, "\\1\n")
  end

  # Returns a string encoded with the IRC color code.
  def irc_color fg, bg
    "\x03#{"%02d" % fg},#{"%02d" % bg}#{self}\x03"
  end
end