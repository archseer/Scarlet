#=========================================#
# // Technical Commands
#=========================================#
# dice <x>d<y> - rolls <x> dies with <y> sides
Scarlet.hear /dice (\d+)d(\d+)/i, :any do
  sides, diecoun = params[1].to_i, params[2].to_i
  sides   = 1 if(sides<=0)
  diecoun = 1 if(diecoun<=0)
  dice    = diecoun.times.collect{|i|1+rand(sides)}
  reply format("%d : %s", dice.inject(0){|r,i|r+i}, dice.inspect)
end
# coin <x> - Flips <x> coins O is heads, and X is tails
Scarlet.hear /coin (\d+)/i, :any do
  count, = params[1].to_i
  reply count.times.collect{|i|rand(2) == 0 ? "O" : "X"}.inspect.gsub('"',"")
end