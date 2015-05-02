hear (/bot ban (?<lvl>[0-3]) (?<nicks>.+)(?:\: (?<reason>.+))?/i) do
  clearance :dev
  description 'Bans a user from using the bot.'
  usage 'bot ban <user>'
  on do
    nicks = params[2].split(" ").compact
    list = []
    sender_nik = Scarlet::Nick.first(:nick => sender.nick)
    nicks.each do |nick_str|
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
    end
    if list.size > 0
      reply "#{list.join ", "} #{list.length == 1 ? "is" : "are"} now banned from using #{server.current_nick} with ban level #{lvl}."
    else
      reply "No one was banned."
    end
  end
end

hear (/bot unban (.+)/i) do
  clearance :dev
  description 'Unbans a user from using the bot.'
  usage 'bot unban <user>'
  on do
    nicks = params[1].split " "
    sender_nik = Scarlet::Nick.first(:nick => sender.nick)
    list = []
    nicks.each do |nick_str|
      next if sender_nik.nick.upcase == nick_str.upcase
      if ban = Scarlet::Ban.first(:nick => nick_str)
        ban.level = 0
        ban.by = sender.nick
        ban.reason = ""
        ban.server.delete(server.config.address)
        ban.save!
        list << ban.nick
      end
    end
    reply "#{server.current_nick} ban was revoked for #{list.join(", ")}."
  end
end

hear (/rename\s+(.+)/i) do
  clearance :dev
  description 'renames the bot to nick.'
  usage 'rename <nick>'
  on do
    send "nick #{params[1].strip}"
  end
end

hear (/filter (.+)/i) do
  clearance :dev
  description %Q(Bans a specific command phrase.
This could be either a single word, or a spaced phrase.
If it's a phrase, it looks for the entire phrase and NOT just
individual words.)
  usage 'filter <phrase>'
  on do
    Scarlet::Command.filter << params[1].strip
  end
end

hear (/unfilter (.+)/i) do
  clearance :dev
  description 'Unbans a specific command phrase.'
  usage 'unfilter <phrase>'
  on do
    Scarlet::Command.filter.delete params[1].strip
  end
end

hear (/restart/i) do
  clearance :dev
  description 'Restarts the bot.'
  usage 'restart'
  on do
    reply 'Restarting myself...'
    server.reconnect
  end
end

[['admin', [:+, :admin]], ['deadmin', [:-, :admin]],
 ['op'   , [:+, :op]]   , ['deop'   , [:-, :op]],
 ['hop'  , [:+, :hop]]  , ['dehop'  , [:-, :hop]],
 ['voice', [:+, :voice]], ['devoice', [:-, :voice]]
].each do |str|
  name, cmd = *str
  hear (/#{name}\s(\S+)/i) do
    clearance :dev
    description 'Nick status control.'
    usage "#{name} <nick>"
    on do
      op, md = *cmd
      if modes_hsh = server.mode_list[md]
        mode = op.to_s + modes_hsh[:prefix].to_s
        server.send "MODE %s #{mode} %s" % [channel, params[1]]
      else
        notify "The network does not support this mode: #{md}"
      end
    end
  end
end

hear (/kick\s+(?<nick>\S+)(?<channel>\s+\#\S+)?(?:\s+(?<reason>.+))?/i) do
  clearance :dev
  description 'Kicks nick from channel, if no channel is given, kicks from the sender channel.'
  usage 'kick <nick> [<channel>] [<reason>]'
  on do
    send "KICK #{params[:channel]||channel} #{params[:nick]} #{params[:reason]}"
  end
end

hear (/kickban\s+(\S+)/i) do
  clearance :dev
  description 'Kickbans nick from channel'
  usage 'kickban <nick>'
  on do
    send "KICKBAN #{params[1]}"
  end
end

hear (/invite\s(\S+)(?:\s(\S+))?/i) do
  clearance :dev
  description 'Invites nick to channel'
  usage 'invite <nick>'
  on do
    send "INVITE #{params[1]} #{(params[2] || '')}"
  end
end
