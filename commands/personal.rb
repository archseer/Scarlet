# login - Logs the user into his bot account.
Scarlet.hear /login/ do
  if !::IrcBot::Nick.where(:nick => sender.nick).empty?
    if !::IrcBot::User.ns_login? server.channels, sender.nick
      server.check_nick_login sender.nick
    else
      notice sender.nick, "#{sender.nick}, you are already logged in!"
    end
  else
    notice sender.nick, "#{sender.nick}, you do not have an account yet. Type !register."
  end
end

# logout - Logs the user out from his bot account.
Scarlet.hear /logout/ do
  if ::IrcBot::User.ns_login? server.channels, sender.nick
    ::IrcBot::User.ns_logout server.channels, sender.nick
    notice sender.nick, "#{sender.nick}, you are now logged out."
  end
end

# register - Registers an account with the bot.
Scarlet.hear /register/ do
  if ::IrcBot::Nick.where(:nick => sender.nick).empty?
    nick = ::IrcBot::Nick.new(:nick => sender.nick).save!
    notice sender.nick, "Successfuly registered with the bot."
  else
    notice sender.nick, "ERROR: You are already registered!"
  end
end

# settings - Change your account settings with the bot
# // Add more later like timezone, and some others
Scarlet.hear /settings (notify_login)[ ](toggle|on|off)/i do
  n = ::IrcBot::Nick.where(:nick => sender.nick).first
  unless n
    case(params[1].upcase)
    when "NOTIFY_LOGIN"
      opt = IrcBot::IcyCommands.str2bool(params[2])
      n.settings[:notify_login] = opt
    end
    n.save!
  else
    notice sender.nick, "You cannot access account settings"
  end
end