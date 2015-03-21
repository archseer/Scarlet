hear (/(?:leave|part)(?:\s(\#\S+)(?:\s(.+))?)?/i) do
  clearance :dev
  description 'Ask bot to leave #channel.'
  usage 'part #<channel>'
  on do
    chan, reason = params[1]||channel, params[2]
    send "PART #{chan} #{reason}"
  end
end

hear (/join\s(.+)/i) do
  clearance :dev
  description 'Ask bot to join #channel or channels.'
  usage 'join <#channel>[,<#channel>,<#channel>]'
  on do
    send "JOIN #{params[1].gsub(' ',',')}"
  end
end

hear (/quit/i) do
  clearance :dev
  description 'Asks the bot to leave the server.'
  usage 'quit'
  on do
    send "QUIT"
  end
end

hear (/privmsg\s(\S+)\s(.+)/i) do
  clearance :dev
  description 'Sends msg to #channel or user.'
  usage 'privmsg <#channel | user> <string>'
  on do
    send "PRIVMSG #{params[1]} #{params[2]}"
  end
end

hear (/notice\s(\S+)\s(.+)/i) do
  clearance :dev
  description 'Sends notice <#channel|user> <string>.'
  usage 'notice <#channel | user> <string>'
  on do
    send "NOTICE #{params[1]} #{params[2]}"
  end
end

hear (/cycle(?:\s(\S+))?/i) do
  clearance :dev
  description 'Leave and rejoin #channel.'
  usage 'cycle <#channel>'
  on do
    if params[1]
      send "CYCLE #{params[1]}"
    else
      server.channels.map(&:name).each { |n| send "CYCLE #{n}" }
    end
  end
end
