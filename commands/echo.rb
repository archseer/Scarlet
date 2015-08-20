# The echo command is simply used for checking if the bot exists, or for testing
# message sending.
hear(/echo\s+(.+)/) do
  clearance nil
  description 'Bot repeats given message.'
  usage 'echo <message>'
  on do
    reply params[1]
  end
end
