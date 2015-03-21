hear (/dice (\d+)d(\d+)/i) do
  clearance :any
  description 'rolls <x> dies with <y> sides.'
  usage 'dice <x>d<y>'
  on do
    sides, diecoun = params[2].to_i, params[1].to_i
    sides   = 1 if sides <= 0
    diecoun = 1 if diecoun <= 0
    dice    = diecoun.times.collect{|i| 1 + rand(sides)}
    reply format("%d : %s", dice.inject(0){|r,i|r+i}, dice.inspect)
  end
end

hear (/coin (\d+)/i) do
  clearance :any
  description 'Flips <x> coins O is heads, and X is tails.'
  usage 'coin <x>'
  on do
    count, = params[1].to_i
    reply count.times.map{ |i| rand(2) == 0 ? 'O' : 'X' }.inspect.gsub('"',"")
  end
end
