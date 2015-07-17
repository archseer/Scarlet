hear (/(?:leave|part)(?:\s+(\#\S+)(?:\s+(.+))?)?/i) do
  clearance &:dev?
  description 'Ask bot to leave #channel.'
  usage 'part #<channel>'
  on do
    chan, reason = params[1]||channel, params[2]
    send "PART #{chan} #{reason}"
  end
end

hear (/join\s+(.+)/i) do
  clearance &:dev?
  description 'Ask bot to join #channel or channels.'
  usage 'join <#channel>[,<#channel>,<#channel>]'
  on do
    send "JOIN #{params[1].gsub(' ',',')}"
  end
end

hear (/quit/i) do
  clearance &:dev?
  description 'Asks the bot to leave the server.'
  usage 'quit'
  on do
    send "QUIT"
  end
end

hear (/send\s+(.+)/) do
  clearance &:dev?
  description 'Sends provided string to server'
  usage 'send <string>'
  on do
    send params[1]
  end
end

hear (/(privmsg|msg)\s+(?<target>\S+)\s(?<message>.+)/i) do
  clearance &:dev?
  description 'Sends msg to #channel or user.'
  usage '(privmsg|msg) <#channel | user> <string>'
  on do
    server.msg params[:target], params[:message]
  end
end

hear (/action\s+(?<target>\S+)\s+(?<message>.+)/) do
  clearance &:dev?
  description 'Sends an action <messafe> to the <channel>'
  usage 'action <channel> <message>'
  on do
    server.msg params[:target], "\x01ACTION #{params[:message]}\x01"
  end
end

hear (/notice\s+(?<target>\S+)\s(?<message>.+)/i) do
  clearance &:dev?
  description 'Sends notice <#channel|user> <string>.'
  usage 'notice <#channel | user> <string>'
  on do
    server.notice params[:target], params[:message]
  end
end

hear (/cycle(?:\s+(?<channel>\S+))?/i) do
  clearance &:dev?
  description 'Leave and rejoin #channel.'
  usage 'cycle <#channel>'
  on do
    if ch = params[:channel].presence
      send "CYCLE #{ch}"
    else
      server.channels.map(&:name).each { |n| send "CYCLE #{n}" }
    end
  end
end
