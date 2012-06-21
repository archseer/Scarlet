Scarlet.hear /(?:leave|part)\s(\#\S+)(?::(.+))?/i, :dev do
  # // part channel reason
  send_data "PART #{params[1]} #{params[2]}"
end
#Scarlet.hear /send\s(.+)/i, :dev do
#  send_data params[1]
#end
Scarlet.hear /privmsg\s(\S+)\s(.+)/i, :dev do
  send_data "PRIVMSG #{params[1]} #{params[2]}"
end
Scarlet.hear /notice\s(\S+)\s(.+)/i, :dev do
  send_data "NOTICE #{params[1]} #{params[2]}"
end
Scarlet.hear /cycle(?:\s(\S+))?/i, :dev do
  if params[1]
    send_data "CYCLE #{params[1]}"
  else
    server.channels.keys.each do |n| send_data 'CYCLE #{n}' end
  end
end