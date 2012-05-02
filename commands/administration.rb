# ban <user> - Bans a user from using the bot.
Scarlet.hear (/ban ([0-3]) (.+)/), :dev do
  lvl   = params[1].to_i
  nicks = params[2].split(" ")
  nicks.each { |nick_str| 
    ban = Scarlet::Ban.where(:nick=>nick_str).first or Scarlet::Ban.new(:nick=>nick_str)
    ban.level = lvl 
    ban.by = sender.nick
    ban.reason = ""
    ban.save!
  }
  reply "#{nicks.join(", ")} #{nicks.length == 1 ? "is" : "are"} now banned from using #{$config.irc_bot.nick} with ban level #{lvl}."
end

# unban <user> - Unbans a user from using the bot.
Scarlet.hear (/unban (.+)/), :dev do
  nicks = params[1].split(" ")
  nicks.each { |nick_str| 
    ban = Scarlet::Ban.where(:nick=>nick_str).first
    if(ban)
      ban.level = 0 
      ban.by = sender.nick
      ban.reason = ""
      ban.save!
    end
  }
  reply "#{$config.irc_bot.nick} ban was revoked for #{nicks.join(", ")}."
end
# rename <nick> - Renames the bot to nick.
Scarlet.hear (/rename\s+(.+)/), :dev do
  send_cmd :nick, :nick => params[1].strip
end

# filter <phrase> - Bans a specific command phrase.
# This could be either a single word, or a spaced phrase. 
# If it's a phrase, it looks for the entire phrase and NOT just
# individual words.
Scarlet.hear (/filter (.+)/), :dev do
  Command.filter << params[1].strip
end
# unfilter <phrase> - Unbans a specific command phrase.
Scarlet.hear (/unfilter (.+)/), :dev do
  Command.filter.delete params[1].strip
end