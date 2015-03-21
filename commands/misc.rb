# encoding: utf-8
# Do it. For science.
hear (/give me\s+(.+)/) do
  clearance :any
  description 'Responds with an action, "giving" the user the requested item.'
  usage 'give me <item>'
  on do
    reply "\x01ACTION gives #{params[1]} to #{sender.nick}!\x01"
  end
end

hear (/show colors/) do
  clearance :dev
  description 'Draws the entire IRC color pallete.'
  usage 'show colors'
  on do
    for i in 0..15
      reply "#{"%02d" % i}".align(10, :center).irc_color(0, i), true
    end
  end
end

hear (/poke\s+(.+)/) do
  clearance :registered
  description 'Sends a notice to <nick>, saying you poked him.'
  usage 'poke <nick>'
  on do
    notice params[1], "#{sender.nick} has poked you."
  end
end
