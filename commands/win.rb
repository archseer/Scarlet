# win <name> - Show some respect to <name>, and give em a win point
Scarlet.hear /win(?:\s(\S+))?/i, :registered do
  given = !!params[1]
  nick = Scarlet::Nick.where(:nick=> params[1]).first
  same = nick ? sender.nick.casecmp(nick.nick) : false
  if nick and !same 
    nick.win_points += 1
    nick.save!
    reply "#{sender.nick} gave #{params[1]} a win!" 
  elsif same 
    reply "You can't give yourself a win!" 
  elsif given and !nick
    reply "You can't win %s" % params[1]
  else
    wins = Scarlet::Nick.where(:nick=> sender.nick).first.win_points
    reply "#{sender.nick} has #{wins} #{"win point".pluralize(wins)}." 
  end
end