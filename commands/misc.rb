Scarlet.hear (/show colors/), :dev do
  for i in 0..15
    reply "#{"%02d" % i}".align(10, :center).irc_color(0, i), true
  end
end

Scarlet.hear (/party/), :registered do
  reply "PARTY! PARTY! YEEEEEEEA BOIIIIIII! ^.^ SO HAPPY, AWESOMEEEEE!"
end