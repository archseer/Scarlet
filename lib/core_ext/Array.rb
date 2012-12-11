class Array
  # Removes values from array exactly once.
  # @param [*Array] values A list of values to subtract
  def subtract_once *values
    values = Set.new values
    self.replace reject { |e| values.include?(e) && values.delete(e) }
  end
end