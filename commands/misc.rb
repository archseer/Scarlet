# encoding: utf-8
# Do it. For science.

Scarlet.hear (/give me (:?a\s)cookie/) do
  reply "\x01ACTION gives #{sender.nick} a cookie!\x01"
end

Scarlet.hear (/give me (:?a\s)potato/), :dev do
  reply "\x01ACTION gives #{sender.nick} a potato!\x01"
end

Scarlet.hear (/OMG/) do
  table = ::Scarlet::InfoTable.new(50)
  table.addHeader "┌─ TODO #1 ─┐"
  table.addRow "┌───────── Sup! ────┐"
  table.addRow "│ Date: sasda       │"
  table.addRow "│ Added by: a       │"
  table.addRow "│ Entry: qqqq       │"
  table.addRow "└───────── Sup! ────┘"
  table.compile.each {|line| reply line, true }
end

Scarlet.hear /test/ do
  ::Scarlet::ColumnTable.test.each {|line| reply line, true }
end


# show colors - Draws the entire IRC color pallete.
Scarlet.hear (/show colors/), :dev do
  for i in 0..15
    reply "#{"%02d" % i}".align(10, :center).irc_color(0, i), true
  end
end

Scarlet.hear (/party/), :registered do
  reply "PARTY! PARTY! YEEEEEEEA BOIIIIIII! ^.^ SO HAPPY, AWESOMEEEEE!"
end
# poke <nick> - Sends a notice to <nick>, saying you poked him.
Scarlet.hear (/poke (.+)/), :registered do
  notice params[1], "#{sender.nick} has poked you."
end

Scarlet.hear (/eval (.+)/), :dev do
  if !Scarlet::Nick.where(:nick => sender.nick).empty? && Scarlet::Nick.where(:nick => sender.nick).first.privileges == 9
    parm = params[1]
  else
    safe = true
    names_list = ["a poopy-head", "a meanie", "a retard", "an idiot"]
    if params[1].match(/(.*(Thread|Process|File|Kernel|system|Dir|IO|fork|while\s*true|require|load|ENV|%x|\`|sleep|Modules|Socket|send|undef|\/0|INFINITY|loop|variable_set|\$|@|Nick.*privileges.*save!|disconnecting\s*\=\s*true).*)/) 
      parm = "\"#{sender.nick} is #{names_list[rand(4)-1]}.\"" 
    else 
      parm = params[1]
    end
    parm.taint
  end

  begin
    t = Thread.new {
      Thread.current[:output] = "==> #{eval(parm)}"
    }
    t.join(10)
    reply t[:output]
  rescue(Exception) => result
    reply "ERROR: #{result.message}".irc_color(4,0)
  end
end