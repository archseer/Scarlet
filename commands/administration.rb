can_ban = lambda do |banner, target|
  # owners can ban anyone
  return true if banner.owner?
  # moderators and above can ban users without an account
  return true if banner.mod? && !target
  # devs can only ban admins and below
  return true if banner.dev? && !target.dev?
  # admins can only ban moderators and below
  return true if banner.admin? && !target.admin?
  # moderators can only other users
  return true if banner.mod? && !target.mod?
  return false
end
can_unban = can_ban

hear (/bot ban (?<lvl>[0-3]) (?<nicks>.+)(?:\s*\:\s+(?<reason>.+))?/i) do
  clearance &:mod?
  description 'Bans a user from using the bot.'
  usage 'bot ban <user>'
  on do
    nicks = params[:nicks].split " "
    ban_level = params[:lvl].to_i
    ban_reason = params[:reason]
    list = []
    sender_nik = find_nick(sender.nick)
    nicks.each do |nick_str|
      #notify "%s is currently not present on this network"
      ban = Scarlet::Ban.first_or_create(nick: nick_str)
      nck = find_nick(nick_str)
      if ban && can_ban.call(sender_nik, nck)
        ban.level = ban_level
        ban.by = sender.nick
        ban.reason = ban_reason
        ban.servers |= [server.config.address]
        list << ban.nick
      else
        notify "You cannot ban #{nick_str}"
      end
      ban.save
    end
    if list.size > 0
      reply "#{list.join ", "} #{list.length == 1 ? "is" : "are"} now banned from using #{server.current_nick} with ban level #{lvl}."
    else
      reply "No one was banned."
    end
  end
end

hear (/bot unban (?<nicks>.+)/i) do
  clearance &:mod?
  description 'Unbans a user from using the bot.'
  usage 'bot unban <user>'
  on do
    nicks = params[:nicks].split " "
    sender_nik = find_nick(sender.nick)
    list = []
    nicks.each do |nick_str|
      if sender_nik.nick.upcase == nick_str.upcase
        reply "You cannot unban yourself!"
        next
      end
      nick = find_nick(nick_str)
      if can_unban.call(sender_nik, nick)
        if ban = Scarlet::Ban.first(nick: nick_str)
          ban.level = 0
          ban.by = sender.nick
          ban.reason = ""
          ban.server.delete(server.config.address)
          ban.save
          list << ban.nick
        end
      else
        reply "You cannot unban #{nick_str}"
      end
    end
    reply "#{server.current_nick} ban was revoked for #{list.join(", ")}."
  end
end

hear (/rename\s+(.+)/i) do
  clearance &:dev?
  description 'renames the bot to nick.'
  usage 'rename <nick>'
  on do
    send "nick #{params[1].strip}"
  end
end

hear (/filter (.+)/i) do
  clearance &:dev?
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
  clearance &:dev?
  description 'Unbans a specific command phrase.'
  usage 'unfilter <phrase>'
  on do
    Scarlet::Command.filter.delete params[1].strip
  end
end

hear (/restart/i) do
  clearance &:dev?
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
  name, (op, mode) = *str
  hear (/#{name}\s(\S+)/i) do
    clearance &:dev?
    description "##{op == :+ ? 'Gives' : 'Removes'} #{mode} for user."
    usage "#{name} <nick>"
    on do
      if modes_hsh = server.mode_list[mode]
        mode = op.to_s + modes_hsh[:prefix].to_s
        server.send "MODE %s #{mode} %s" % [channel, params[1]]
      else
        notify "The network does not support this mode: #{mode}"
      end
    end
  end
end

hear (/kick\s+(?<nick>\S+)(?<channel>\s+\#\S+)?(?:\s+(?<reason>.+))?/i) do
  clearance &:dev?
  description 'Kicks nick from channel, if no channel is given, kicks from the sender channel.'
  usage 'kick <nick> [<channel>] [<reason>]'
  on do
    send "KICK #{params[:channel]||channel} #{params[:nick]} #{params[:reason]}"
  end
end

hear (/kickban\s+(\S+)/i) do
  clearance &:dev?
  description 'Kickbans nick from channel'
  usage 'kickban <nick>'
  on do
    send "KICKBAN #{params[1]}"
  end
end

hear (/invite\s(\S+)(?:\s(\S+))?/i) do
  clearance &:dev?
  description 'Invites nick to channel'
  usage 'invite <nick>'
  on do
    send "INVITE #{params[1]} #{(params[2] || '')}"
  end
end
