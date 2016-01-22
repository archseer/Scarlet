hear(/remind (?<nick>.+?) in (?<time>.+?) to (?<action>.+)[.!]?/i) do
  clearance(&:registered?)
  description 'Set a reminder in <time> to do an <action>.'
  usage 'remind <nick> in <time> to <action>'
  on do
    nick = handle_special_nick(params[:nick])
    t = params[:time]
    action = params[:action].strip

    mesg = if nick == sender.nick
      "#{nick}, you asked me to remind you to #{action}."
    else
      "#{sender.nick} asked me to remind you to #{action}."
    end

    server.reminder_scheduler.in t, sender: sender.nick, receiver: nick, message: mesg

    if nick == sender.nick
      reply "Ok, I'll remind you in #{t}."
    else
      reply "Ok, I'll remind #{nick} in #{t}."
    end
  end
end
