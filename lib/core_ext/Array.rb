class Array
  def subtract_once *values
    values = Set.new values
    self.replace reject { |e| values.include?(e) && values.delete(e) }
  end
end