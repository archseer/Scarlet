require 'scarlet/plugins/klik'

# klik - Is a one click stopwatch
hear /klik/i, :registered do
  n = Scarlet::Plugins.klik.round(2)
  reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
end

# time - Prints the current owners time
hear /time(?:\s(\S+))?/i, :registered do
  unless params[1]
    reply Time.now
  else
    nck = params[1].gsub(/-me/i, sender.nick)
    if nick = Scarlet::Nick.first(:nick => nck)
      if zone_str = nick.settings[:timezone]
        reply Time.now.in_time_zone(zone_str)
      else
        reply "Your timezone is not set: Use !settings timezone your_timezone_string"
      end
    else
      reply 'Cannot view time for "%s".' % params[1]
    end
  end
end

# update <name>? - Just to nag the crap out of Speed
hear /update(?:\s(\S+))?/i, :dev do
  notice params[1]||"Speed", "%s demandes que tu mettre à jour moi!" % sender.nick
  notify "Notice sent."
end

hear /dcc/i, :owner do
  Scarlet::DCC.send @event, 'chellocat.jpg'
end
