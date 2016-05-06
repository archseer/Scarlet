config = load_config_file do
  {
    default: 5,
    limit: 10
  }
end

hear(/recall(?:\s+(\d+))?/) do
  clearance(&:registered?)
  description "Returns the last n messages, default is #{config[:default]}, limit is #{config[:limit]}."
  usage 'recall [<count>]'
  on do
    if event.channel
      recall_depth = (params[1] || config[:default]).to_i.minmax(1, config[:limit]) + 1
      logs = server.logs.channel(event.channel)
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
