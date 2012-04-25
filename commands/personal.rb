# logout - Logs the user out from the bot.
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
    notice sender.nick, "ERROR: You are already registered!".irc_color(4,0)
  end
end