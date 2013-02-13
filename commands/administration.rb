# bot ban <user> - Bans a user from using the bot.
Scarlet.hear /bot ban (?<lvl>[0-3]) (?<nicks>.+)(?:\: (?<reason>.+))?/i, :dev do
  nicks = params[2].split(" ").compact
  list = []
  sender_nik = Scarlet::Nick.first(:nick => sender.nick)
  nicks.each { |nick_str|
    #notify "%s is currently not present on this network"
    ban = Scarlet::Ban.first_or_create(:nick => nick_str)
    nck = Scarlet::Nick.first(:nick => nick_str)
    if ban && (nck ? nck.privileges : 0) < sender_nik.privileges
      ban.level = params[:lvl].to_i
      ban.by = sender.nick
      ban.reason = params[:reason]
      ban.servers |= [server.config.address]
      list << ban.nick
    else
      notify "You cannot ban #{nick_str}"
    end
    ban.save!
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
  sender_nik = Scarlet::Nick.first(:nick => sender.nick)
  list = []
  nicks.each { |nick_str|
    next if sender_nik.nick.upcase == nick_str.upcase
    if ban = Scarlet::Ban.first(:nick => nick_str)
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
  server.reconnect
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
    op, md = str[1]
    if modes_hsh = server.mode_list[md]
      mode = op.to_s + modes_hsh[:prefix].to_s
      server.send "MODE %s #{mode} %s" % [channel, params[1]]
    else
      notify "The network does not support this mode: #{md}"
    end
  end
}

# kick <nick> <channel> : <reason>
Scarlet.hear /kick\s(?<nick>\S+)(?<channel>\s\#\S+)?(?:\s\:\s(?<reason>.+))?/i, :dev do
  send "KICK #{params[:channel]||channel} #{params[:nick]} #{params[:reason]}"
end

Scarlet.hear /kickban\s(\S+)/i, :dev do
  send "KICKBAN #{params[1]}"
end

Scarlet.hear /invite\s(\S+)(?:\s(\S+))?/i, :dev do
  send "INVITE #{params[1]}" + (params[2] ? " #{params[2]}" : "")
end
