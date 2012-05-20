# win <name> - Show some respect to <name>, and give em a win point
Scarlet.hear /win[ ]*(\S*)/i, :registered do
  n = Scarlet::Nick.where(:nick=> params[1]).first
  sw = n ? sender.nick.downcase == n.nick.downcase : false
  if(n && !sw)
    n.win_points += 1
    n.save!
    reply "#{sender.nick} gave #{params[1]} a win!" 
  elsif(sw)
    reply "You can't give yourself a win!" 
  else
    wins = Scarlet::Nick.where(:nick=> sender.nick).first.win_points
    reply "#{sender.nick} has #{wins} #{"win point".pluralize(wins)}." 
  end
end