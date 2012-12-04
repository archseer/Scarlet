class String
  def word_wrap line_width = 80
    s.gsub(/(.{1,#{line_width}})(\s+|\Z)/, "\\1\n")
  end

  def irc_color fg, bg
    "\x03#{"%02d" % fg},#{"%02d" % bg}#{self}\x03"
  end
end