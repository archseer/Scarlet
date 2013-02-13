# remind me in <time> to <action> - Set a reminder in <time> to do an <action>
Scarlet.hear /remind me in (?<time>.+?) to (?<action>.+)[.!]?/i do
  server.scheduler.in params[:time] do
    msg sender.nick, "#{sender.nick}, you asked me to remind you to #{params[:action]}."
  end
end
