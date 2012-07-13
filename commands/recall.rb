Scarlet.hear /recall/ do
  if channel
    logs = Scarlet::Log.channel(channel).privmsg.sort(:created_at.desc).limit(6).all.reverse 
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