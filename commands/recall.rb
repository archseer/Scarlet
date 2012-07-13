# recall [<int>]- returns the last n messages, by default n is 5
Scarlet.hear /recall(?:\s(\d+))?/ do
  if channel
    recall_depth = ([[params[1],10].min,1].max || 5) + 1
    logs = Scarlet::Log.channel(channel).privmsg.sort(:created_at.desc).limit(recall_depth).all.reverse 
    # because we use limit, that limits to the first n elements. 
    # if we want to get the last n, we need to reverse order, then limit then reverse again
    logs.pop # remove the newest message, which is the user saying '!recall'
    logs.each do |log|
      notice sender.nick, "<#{log.nick}> #{log.message}"
    end
  else
    reply "You cannot use recall outside a channel!"
  end
end