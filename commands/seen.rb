require 'time-lord'

hear (/seen (?<nick>\S+)/i) do
  clearance :registered
  description 'When was the last time you saw nick?'
  usage 'seen <nick>'
  on do
    log = Scarlet::Log.nick(params[:nick]).sort_by(&:updated_at).last
    unless log
      reply "Sorry, I have never seen #{params[:nick]}."
      next
    end

    message = "#{log.nick} was last seen #{Time.at(log.updated_at).ago.to_words}"
    case log.command.downcase.to_sym
    when :privmsg
      message << " in #{log.target}" unless log.target.downcase == channel
      if log.message =~ /\u0001ACTION (.+)\u0001/
        message << " doing '/me #{$1}'."
      else
        message << " saying '#{log.message}'."
      end
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
end
