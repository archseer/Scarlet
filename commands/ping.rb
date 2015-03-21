hear (/ping/i) do
  clearance :any
  description 'Pings the bot, should respond with PONG!'
  usage 'ping'
  on do
    reply 'PONG!'
  end
end
