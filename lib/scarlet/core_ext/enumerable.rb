module Enumerable
  def limit(limit)
    return to_enum :limit, limit unless block_given?
    n = 0
    each do |*e|
      break if n >= limit
      yield(*e)
      n += 1
    end
  end
end
