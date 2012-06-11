# login - Logs the user into his bot account.
Scarlet.hear /login/i do
  if !Scarlet::Nick.where(:nick => sender.nick).empty?
    if !Scarlet::User.ns_login? server.channels, sender.nick
      server.check_nick_login sender.nick
    else
      notice sender.nick, "#{sender.nick}, you are already logged in!"
    end
  else
    notice sender.nick, "#{sender.nick}, you do not have an account yet. Type !register."
  end
end

# logout - Logs the user out from his bot account.
Scarlet.hear /logout/i do
  if Scarlet::User.ns_login? server.channels, sender.nick
    Scarlet::User.ns_logout server.channels, sender.nick
    notice sender.nick, "#{sender.nick}, you are now logged out."
  end
end

# register - Registers an account with the bot.
Scarlet.hear /register/i do
  if Scarlet::Nick.where(:nick => sender.nick).empty?
    nick = Scarlet::Nick.new(:nick => sender.nick).save!
    notice sender.nick, "Successfuly registered with the bot."
  else
    notice sender.nick, "ERROR: You are already registered!"
  end
end

# // settings - Change your account settings with the bot
# // notify_login 
# // timezone
# // 
# set timezone <timezone> - self-explanatory; used with !time command
Scarlet.hear /set(?: my)? timezone (.+)/i do
  n = Scarlet::Nick.where(:nick => sender.nick).first
  if n
    if TZInfo::Timezone.all_identifiers.include? params[1]
      n.settings[:timezone] = params[1]
      notice sender.nick, "Your current Time Zone is: %s" % n.settings[:timezone]
    else
      notice sender.nick, "Invalid Time Zone: %s" % params[1]
    end
  else
    notice sender.nick, "You cannot access account settings, are you logged in?"
  end
end
# notify login <toggle|on|off> - Should you be notified when you auto-login?
Scarlet.hear /notify(?: me)? login (toggle|on|off)/i do
  n = Scarlet::Nick.where(:nick => sender.nick).first
  if n 
    opt = params[1].str2bool(!!n.settings[:notify_login])
    n.settings[:notify_login] = opt
    notice sender.nick, "You will #{opt ? "" : "NOT "}be notified on bot login"
  else
    notice sender.nick, "You cannot access account settings, are you logged in?"
  end
end