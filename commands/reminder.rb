hear(/remind\s+(?<nick>.+?)\s+(?<time>.+?)\s+to\s+(?<action>.+[.!]?)/i) do
  clearance(&:registered?)
  description 'Set a reminder in <time> to do an <action>.'
  usage 'remind <nick> in <time> to <action>'
  on do
    nick = handle_special_nick(params[:nick])
    t = params[:time]
    action = params[:action].strip

    mesg = if nick == sender.nick
      "#{nick}, you asked me to remind you to #{action}"
    else
      "#{sender.nick} asked me to remind you to #{action}"
    end

    added = server.reminder_scheduler.add(t,
      sender: sender.nick,
      receiver: nick,
      message: mesg)

    if added
      if nick == sender.nick
        reply "Ok, I'll remind you #{t}."
      else
        reply "Ok, I'll remind #{nick} #{t}."
      end
    else
      reply "Error, Could not add reminder, something is wrong with the time provided!"
    end
  end
end
