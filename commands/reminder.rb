hear (/remind me in (?<time>.+?) to (?<action>.+)[.!]?/i) do
  clearance :registered
  description 'Set a reminder in <time> to do an <action>.'
  usage 'remind me in <time> to <action>'
  on do
    server.scheduler.in params[:time] do
      msg sender.nick, "#{sender.nick}, you asked me to remind you to #{params[:action]}."
    end
  end
end
