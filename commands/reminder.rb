hear(/remind (?<nick>.+?) in (?<time>.+?) to (?<action>.+)[.!]?/i) do
  clearance(&:registered?)
  description 'Set a reminder in <time> to do an <action>.'
  usage 'remind <nick> in <time> to <action>'
  on do
    nick = handle_special_nick(params[:nick])
    t = params[:time]
    server.scheduler.in t do
      if nick == sender.nick
        msg nick, "#{nick}, you asked me to remind you to #{params[:action]}."
      else
        msg nick, "#{sender.nick} asked me to remind you to #{params[:action]}."
      end
    end
    if nick == sender.nick
      reply "Ok, I'll remind you in #{t}."
    else
      reply "Ok, I'll remind #{nick} in #{t}."
    end
  end
end
