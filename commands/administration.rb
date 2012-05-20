# ban <user> - Bans a user from using the bot.
Scarlet.hear /ban ([0-3]) (.+)(?:\: (.+))?/i, :dev do
  lvl   = params[1].to_i
  nicks = params[2].split(" ").compact
  reason= params[3].to_s
begin 
  nicks.each { |nick_str| 
    Scarlet::Ban.new(:nick=>nick_str).save! if Scarlet::Ban.where(:nick=>nick_str).empty?
    ban = Scarlet::Ban.where :nick=>nick_str
    usr = ban.first
    if usr
      reply "Setting ban for #{nick_str}"
      #reply "Ban object #{ban}"
      usr.level = lvl 
      usr.by = sender.nick
      usr.reason = reason
    end  
    usr.save!
  }
  reply "#{nicks.join ", "} #{nicks.length == 1 ? "is" : "are"} now banned from using #{$config.irc_bot.nick} with ban level #{lvl}."
rescue => ex
  notice sender.nick, "Ban Failed #{ex.message}"
end  
end

# unban <user> - Unbans a user from using the bot.
Scarlet.hear /unban (.+)/i, :dev do
  nicks = params[1].split " "
  nicks.each { |nick_str| 
    ban = Scarlet::Ban.where(:nick=>nick_str).first
    if ban
      ban.level = 0 
      ban.by = sender.nick
      ban.reason = ""
      ban.save!
    end
  }
  reply "#{$config.irc_bot.nick} ban was revoked for #{nicks.join(", ")}."
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
  server.send_cmd :quit, :quit => $config.irc_bot.quit
  EM.add_timer(1) { server.unbind }
end