# "Usage: ban <user> [<user>...]", "Usage: unban <user> [<user>...]", rename <new_bot_nick>
Scarlet.hear (/ban (.+)/), :dev do
  nicks = params[1].split(" ")
  nicks.each {|n| server.banned << n }
  reply "#{nicks.join(", ")} #{nicks.length == 1 ? "is" : "are"} now banned from using #{$config.irc_bot.nick}."
end

Scarlet.hear (/unban (.+)/), :dev do
  nicks = params[1].split(" ")
  nicks.each {|n| server.banned.delete n }
  reply "#{$config.irc_bot.nick} ban was revoked for #{nicks.join(", ")}."
end

Scarlet.hear (/rename\s+(.+)/), :dev do
  send_cmd :nick, :nick => params[1].chomp
end