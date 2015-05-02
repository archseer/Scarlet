hear (/ping/i) do
  clearance :any
  description 'Pings the bot, should respond with PONG!'
  usage 'ping'
  on do
    reply 'PONG!'
  end
end

hear (/pong/i) do
  clearance :any
  description 'Pongs the bot, should respond with PING!'
  usage 'pong'
  on do
    reply 'PING!'
  end
end
