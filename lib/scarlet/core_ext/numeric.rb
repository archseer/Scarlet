class Numeric
  def minmax(a, b)
    self < a ? a : (self > b ? b : self)
  end
end
