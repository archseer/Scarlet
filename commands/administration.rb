# bot ban <user> - Bans a user from using the bot.
Scarlet.hear /bot ban ([0-3]) (.+)(?:\: (.+))?/i, :dev do
  lvl   = params[1].to_i
  nicks = params[2].split(" ").compact
  reason= params[3].to_s
  list = []
  sender_nik = Scarlet::Nick.where(:nick=>sender.nick).first
  nicks.each { |nick_str|
    #notice sender.nick, "%s is currently not present on this network"
    Scarlet::Ban.new(:nick=>nick_str).save! if Scarlet::Ban.where(:nick=>nick_str).empty?
    usr = Scarlet::Ban.where(:nick=>nick_str).first
    nck = Scarlet::Nick.where(:nick=>nick_str).first
    if usr && (nck ? nck.privileges : 0) < sender_nik.privileges
      usr.level = lvl
      usr.by = sender.nick
      usr.reason = reason
      usr.servers |= [server.config.address]
      list << usr.nick
    else
      notice sender.nick, "You cannot ban %s" % nick_str
    end
    usr.save!
  }
  if list.size > 0
    reply "#{list.join ", "} #{list.length == 1 ? "is" : "are"} now banned from using #{server.current_nick} with ban level #{lvl}."
  else
    reply "No one was banned."
  end
end

# bot unban <user> - Unbans a user from using the bot.
Scarlet.hear /bot unban (.+)/i, :dev do
  nicks = params[1].split " "
  sender_nik = Scarlet::Nick.where(:nick=>sender.nick).first
  list = []
  nicks.each { |nick_str|
    next if sender_nik.nick.upcase == nick_str.upcase
    ban = Scarlet::Ban.where(:nick=>nick_str).first
    if ban
      ban.level = 0
      ban.by = sender.nick
      ban.reason = ""
      ban.server.delete(server.config.address)
      ban.save!
      list << ban.nick
    end
  }
  reply "#{server.current_nick} ban was revoked for #{list.join(", ")}."
end
# rename <nick> - Renames the bot to nick.
Scarlet.hear /rename\s+(.+)/i, :dev do
  send_cmd :nick, :nick => params[1].strip
end

# filter <phrase> - Bans a specific command phrase.
# This could be either a single word, or a spaced phrase.
# If it's a phrase, it looks for the entire phrase and NOT just
# individual words.
Scarlet.hear /filter (.+)/i, :dev do
  Scarlet::Command.filter << params[1].strip
end
# unfilter <phrase> - Unbans a specific command phrase.
Scarlet.hear /unfilter (.+)/i, :dev do
  Scarlet::Command.filter.delete params[1].strip
end
# restart - Restarts the bot.
Scarlet.hear /restart/i, :dev do
  reply 'Restarting myself...'
  server.send_cmd :quit, :quit => Scarlet.config.quit
  EM.add_timer(1) { server.unbind }
end

# // Good ol' bot commands
# op <nick> - Give Operator Status to <nick>
# hop <nick> - Give Half-Op Status to <nick>
# voice <nick> - Give Voice Status to <nick>
#//ban <str> 
#// - Bans <str>
# kick <nick> - Kicks <nick>
#flags = {"q"=>:owner,"a"=>:admin,"o"=>:operator,"h"=>:halfop,"v"=>:voice,"r"=> :registered}
[["admin",[:+,:admin]],["deadmin",[:-,:admin]],
 ["op"   ,[:+,:op]]   ,["deop"   ,[:-,:op]],
 ["hop"  ,[:+,:hop]]  ,["dehop"  ,[:-,:hop]],
 ["voice",[:+,:voice]],["devoice",[:-,:voice]]
].each { |str|
  Scarlet.hear /#{str[0]}\s(\S+)/i, :dev do
    op,md = str[1]
    modes_hsh = server.mode_list[md]
    unless modes_hsh
      notice sender.nick, "The network does not support this mode: #{md}"
    else
      mode = op.to_s + modes_hsh[:prefix].to_s
      server.send_data "mode %s #{mode} %s" % [channel,params[1]]
    end
  end
}
#Scarlet.hear /kick (\S+(?:\s*,\s*\S+)*)(?: \#(\w+))?[ ]*(?:\: (.+))/i, :dev do
# kick <nick> <channel> : <reason>
Scarlet.hear /kick\s(?<nick>\S+)(?<channel>\s\#\S+)?(?:\s\:\s(?<reason>.+))?/i, :dev do
  send_data "KICK #{params[:channel]||channel} #{params[:nick]} #{params[:reason]}"
end
Scarlet.hear /kickban\s(\S+)/i do
  send_data "KICKBAN #{params[1]}"
end
Scarlet.hear /invite\s(\S+)(?:\s(\S+))?/i, :dev do
  send_data "INVITE #{params[1]}" + (params[2] ? " #{params[2]}" : "")
end