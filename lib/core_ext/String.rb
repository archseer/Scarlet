class String
  # Word wraps the string to the specified length.
  # @param [Integer] line_width The maximum width of the line.
  def word_wrap line_width = 80
    self.gsub(/(.{1,#{line_width}})(\s+|\Z)/, "\\1\n")
  end

  # Encodes a string with the IRC color code.
  # @param [Integer] fg A number between 0 and 15 that sets the foreground color.
  # @param [Integer] bg A number between 0 and 15 background color.
  # @return [String] a string encoded with the IRC color code.
  def irc_color fg, bg
    "\x03#{"%02d" % fg},#{"%02d" % bg}#{self}\x03"
  end
end