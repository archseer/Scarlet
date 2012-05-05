# login - Logs the user into his bot account.
Scarlet.hear /login/ do
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
Scarlet.hear /logout/ do
  if Scarlet::User.ns_login? server.channels, sender.nick
    Scarlet::User.ns_logout server.channels, sender.nick
    notice sender.nick, "#{sender.nick}, you are now logged out."
  end
end

# register - Registers an account with the bot.
Scarlet.hear /register/ do
  if Scarlet::Nick.where(:nick => sender.nick).empty?
    nick = Scarlet::Nick.new(:nick => sender.nick).save!
    notice sender.nick, "Successfuly registered with the bot."
  else
    notice sender.nick, "ERROR: You are already registered!"
  end
end

# settings - Change your account settings with the bot
# // notify_login 
# // timeoffset
# // 
Scarlet.hear /settings (notify_login[ ](?:toggle|on|off)|timeoffset[ ]((?:day|hour|minute|second)s?)(\d+))/i do
  n = Scarlet::Nick.where(:nick => sender.nick).first
  if(n)
    case(params[1])
    when /notify_login[ ](?:toggle|on|off)/i
      opt = Scarlet::IcyCommands.str2bool($1)
      n.settings[:notify_login] = opt
      notice sender.nick, "You will #{opt ? "NOT" : ""} be notified on bot login"
    when /timeoffset[ ](day|hour|minute|second|check)s?[ ]([+-]?\d+)/i
      n.settings[:timeoffset] ||= {:day=>0,:hour=>0,:minute=>0,:second=>0} # // Preset
      type, value = $1, $2.to_i
      unless(type.upcase == "CHECK")
        n.settings[:timeoffset][type.downcase.to_sym] = value
      else
        notice sender.nick, "Your current time Offset: Days[%d] Hours[%d] Minutes[%d] Seconds[%d]" % n.settings[:timeoffset].get_values(:day,:hour,:minute,:second)
      end
    end
    n.save!
  else
    notice sender.nick, "You cannot access account settings, are you logged in?"
  end
end