# part <#channel> - ask bot to leave #channel
Scarlet.hear /(?:leave|part)(?:\s(\#\S+)(?:\s(.+))?)?/i, :dev do
  chan, reason = params[1]||channel, params[2]
  send "PART #{chan} #{reason}"
end

# join <#channel>[,<#channel>,<#channel>] - ask bot to join #channel or channels
Scarlet.hear /join\s(.+)/i, :dev do
  send "JOIN #{params[1].gsub(' ',',')}"
end

# quit -
Scarlet.hear /quit/i, :dev do
  send "QUIT"
end

# send <string> - send data to the server
#Scarlet.hear /send\s(.+)/i, :dev do
#  send params[1]
#end

# privmsg <#channel|user> <string> - msg to #channel or user
Scarlet.hear /privmsg\s(\S+)\s(.+)/i, :dev do
  send "PRIVMSG #{params[1]} #{params[2]}"
end

# notice <#channel|user> <string> - send notice to @channel or user
Scarlet.hear /notice\s(\S+)\s(.+)/i, :dev do
  send "NOTICE #{params[1]} #{params[2]}"
end

# cycle <#channel> - leave and rejoin #channel
Scarlet.hear /cycle(?:\s(\S+))?/i, :dev do
  if params[1]
    send "CYCLE #{params[1]}"
  else
    server.channels.map(&:name).each { |n| send "CYCLE #{n}" }
  end
end
