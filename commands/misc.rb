# encoding: utf-8
# Do it. For science.

# give me <item> - Responds with an action, "giving" the user the requested item.
Scarlet.hear (/give me (.+)/) do
  reply "\x01ACTION gives #{params[1]} to #{sender.nick}!\x01"
end

# show colors - Draws the entire IRC color pallete.
Scarlet.hear (/show colors/), :dev do
  for i in 0..15
    reply "#{"%02d" % i}".align(10, :center).irc_color(0, i), true
  end
end

# poke <nick> - Sends a notice to <nick>, saying you poked him.
Scarlet.hear (/poke (.+)/), :registered do
  nick = context_nick params[1]
  notice nick, "#{sender.nick} has poked you."
end

Scarlet.hear (/eval (.+)/), :dev do
  begin
    t = Thread.new {
      Thread.current[:output] = "==> #{eval(params[1])}"
    }
    t.join(10)
    reply t[:output] if t[:output].size > 4
  rescue(Exception) => result
    reply "ERROR: #{result.message}".irc_color(4,0)
  end
end
