hear (/recall(?:\s+(\d+))?/) do
  clearance &:registered?
  description 'Returns the last n messages, default is 5, limit is 5.'
  usage 'recall [<count>]'
  on do
    if channel
      recall_depth = ([[(params[1] || 5).to_i, 5].min, 1].max) + 1
      logs = Scarlet::Log.channel(channel)
        .select { |o| o.command.to_s == 'PRIVMSG' }
        .sort { |a, b| b.updated_at <=> a.updated_at }
        .limit(recall_depth)
        .to_a
        .reverse
      # because we use limit, that limits to the first n elements.
      # if we want to get the last n, we need to reverse order, then limit then reverse again
      logs.pop # remove the newest message, which is the user saying '!recall'
      logs.each do |log|
        if message = log.message.match(/\u0001ACTION (.+)\u0001/)
          notify "* #{log.nick} #{message[1]}"
        else
          notify "<#{log.nick}> #{log.message}"
        end
      end
    else
      reply "You cannot use recall outside a channel!"
    end
  end
end
