config = load_config_file do
  {
    dies: {
      sides_limit: 24,
      dies_limit: 12
    },
    coins: {
      limit: 24
    }
  }
end

hear(/dice\s+(?<dies>\d+)d(?<sides>\d+)/i) do
  clearance nil
  description 'rolls <x> dies with <y> sides.'
  usage 'dice <x>d<y>'
  on do
    dies  = params[:dies].to_i.minmax(1, config.dig(:dies, :dies_limit))
    sides = params[:sides].to_i.minmax(4, config.dig(:dies, :sides_limit))
    sides = 1 if sides <= 0
    dies  = 1 if dies <= 0
    dice  = dies.times.collect { |i| 1 + rand(sides) }
    reply format("%d : %s", dice.inject(:+), dice.inspect)
  end
end

hear(/coin\s+(?<coins>\d+)/i) do
  clearance nil
  description 'Flips <x> coins O is heads, and X is tails.'
  usage 'coin <x>'
  on do
    count = params[:coins].to_i.minmax(1, config.dig(:coins, :limit))
    reply count.times.map{ |i| rand(2) == 0 ? 'O' : 'X' }.inspect.gsub('"',"")
  end
end
