hear(/(?:leave|part)(?:\s+(\#\S+)(?:\s+(.+))?)?/i) do
  clearance(&:sudo?)
  description 'Ask bot to leave #channel.'
  usage 'part #<channel>'
  on do
    chan, reason = params[1]||channel, params[2]
    send_data "PART #{chan} #{reason}"
  end
end

hear(/join\s+(.+)/i) do
  clearance(&:sudo?)
  description 'Ask bot to join #channel or channels.'
  usage 'join <#channel>[,<#channel>,<#channel>]'
  on do
    send_data "JOIN #{params[1].gsub(' ',',')}"
  end
end

hear(/quit/i) do
  clearance(&:sudo?)
  description 'Asks the bot to leave the server.'
  usage 'quit'
  on do
    send_data "QUIT"
  end
end

hear(/send\s+(.+)/) do
  clearance(&:sudo?)
  description 'Sends provided string to server'
  usage 'send <string>'
  on do
    send_data params[1]
  end
end

hear(/(privmsg|msg)\s+(?<target>\S+)\s(?<message>.+)/i) do
  clearance(&:sudo?)
  description 'Sends msg to #channel or user.'
  usage '(privmsg|msg) <#channel | user> <string>'
  on do
    msg params[:target], params[:message]
  end
end

hear(/action\s+(?<target>\S+)\s+(?<message>.+)/) do
  clearance(&:sudo?)
  description 'Sends an action <messafe> to the <channel>'
  usage 'action <channel> <message>'
  on do
    msg params[:target], "\x01ACTION #{params[:message]}\x01"
  end
end

hear(/notice\s+(?<target>\S+)\s(?<message>.+)/i) do
  clearance(&:sudo?)
  description 'Sends notice <#channel|user> <string>.'
  usage 'notice <#channel | user> <string>'
  on do
    notice params[:target], params[:message]
  end
end

hear(/cycle(?:\s+(?<channel>\S+))?/i) do
  clearance(&:sudo?)
  description 'Leave and rejoin #channel.'
  usage 'cycle <#channel>'
  on do
    if ch = params[:channel].presence
      send_data "CYCLE #{ch}"
    else
      event.server.channels.map(&:name).each { |n| send_data "CYCLE #{n}" }
    end
  end
end
