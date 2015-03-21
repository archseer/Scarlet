hear (/win(?:\s(\S+))?/i) do
  clearance :registered
  description 'Show some respect to <name>, and give em a win point.'
  usage 'win <name>'
  on do
    given = !!params[1]
    nick = Scarlet::Nick.first(:nick => params[1])
    same = nick ? sender.nick.downcase == nick.nick.downcase : false
    if nick and !same
      nick.win_points += 1
      nick.save!
      reply "#{sender.nick} gave #{params[1]} a win!"
    elsif given and !nick
      reply "You can't win %s." % params[1]
    elsif same
      reply "You can't give yourself a win!"
    else
      wins = Scarlet::Nick.first(:nick=> sender.nick).win_points
      reply "#{sender.nick} has #{wins} #{"win point".pluralize(wins)}."
    end
  end
end
