Scarlet.hear /seen (?<nick>\S+)/ do
  log = Scarlet::Log.nick(params[:nick]).sort(:created_at.asc).last
  unless log
    reply "Sorry, I have never seen #{params[:nick]}."
    next
  end

  message = "#{log.nick} was last seen #{log.created_at.ago_in_words}"
  case log.command.downcase.to_sym
    when :privmsg
      message << " in #{log.target}" unless log.target.downcase == channel
      message << " saying '#{log.message}'."
    when :nick
      message << " changing nickname to '#{log.target}'."
    when :join
      message << " joining channel #{log.target}."
    when :part
      message << " leaving channel #{log.target}."
    when :quit
      message << " quiting IRC."
    else
      message = "Not yet implemented!"
  end
  reply message if message
end