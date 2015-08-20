hear(/remind me in (?<time>.+?) to (?<action>.+)[.!]?/i) do
  clearance(&:registered?)
  description 'Set a reminder in <time> to do an <action>.'
  usage 'remind me in <time> to <action>'
  on do
    t = params[:time]
    server.scheduler.in t do
      msg sender.nick, "#{sender.nick}, you asked me to remind you to #{params[:action]}."
    end
    reply "Ok, I'll remind you in #{t}."
  end
end
