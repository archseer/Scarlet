# recall [<int>]- returns the last n messages, by default n is 5
Scarlet.hear /recall(?:\s(\d+))?/ do
  if channel
    recall_depth = ([[(params[1]||5).to_i,5].min,1].max) + 1
    logs = Scarlet::Log.channel(channel).privmsg.sort(:created_at.desc).limit(recall_depth).all.reverse 
    # because we use limit, that limits to the first n elements. 
    # if we want to get the last n, we need to reverse order, then limit then reverse again
    logs.pop # remove the newest message, which is the user saying '!recall'
    logs.each do |log|
      if message = log.message.match(/\u0001ACTION (.+)\u0001/)
        notice sender.nick, "* #{log.nick} #{message[1]}", true
      else
        notice sender.nick, "<#{log.nick}> #{log.message}", true
      end
    end
  else
    reply "You cannot use recall outside a channel!"
  end
end