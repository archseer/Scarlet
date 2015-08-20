hear(/user group (?<cmd>add|remove) (?<nick>\S+) (?<groups>.+)/i) do
  clearance(&:sudo?)
  description 'Adds user to the given groups'
  usage 'user group (add|remove) <nick> <groups>'
  on do
    admin = sender_nick
    groups = params[:groups].words.uniq
    if groups.delete('owner')
      reply "You may not set the owner group!"
    end
    cmd = params[:cmd]
    with_nick do |nick|
      unless admin.root?
        if nick.sudo?
          reply "You cannot modify another sudo's groups"
          throw :skip
        elsif same_nick?(admin, nick)
          reply "You cannot modify your own groups"
          throw :skip
        end
      end
      case cmd
      when 'add'
        nick.groups |= groups
      when 'remove'
        nick.groups -= groups
      else
        raise RuntimeError, "Somthing funky is going on here."
      end
      nick.save
      reply "User #{nick.nick} groups: #{nick.groups}"
    end
  end
end

hear(/user groups(?:\s+(?<nick>\S+))?/i) do
  clearance nil
  description 'Displays which groups the user belongs to'
  usage 'user groups [<nick>]'
  on do
    with_nick params[:nick] || sender.nick do |nick|
      reply nick.groups.join(" ")
    end
  end
end

hear(/user status(?:\s+(?<nick>\S+))?/i) do
  clearance nil
  description 'Displays whether the user is logged in or not'
  usage 'user status [<nick>]'
  on do
    with_nick params[:nick] || sender.nick do |nick|
      user = event.server.users.get(nick.nick)
      if user.ns_login
        reply "#{nick.nick} is logged in"
      else
        reply "#{nick.nick} does not appear to be logged in"
      end
    end
  end
end
