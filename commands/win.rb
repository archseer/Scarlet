hear (/win(?:\s+(?<nick>\S+))?/i) do
  clearance &:registered?
  description 'Show some respect to <name>, and give em a win point.'
  usage 'win <name>'
  on do
    if nickname = params[:nick].presence
      with_nick(nickname) do |nick|
        if same_nick?(nick, sender.nick)
          reply "You can't give yourself a win!"
        else
          nick.win_points += 1
          nick.save
          reply "#{sender.nick} gave #{params[1]} a win!"
        end
      end
    else
      wins = Scarlet::Nick.first(nick: sender.nick).win_points
      reply "#{sender.nick} has #{wins} #{"win point".pluralize(wins)}."
    end
  end
end
