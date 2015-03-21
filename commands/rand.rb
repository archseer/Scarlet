require 'scarlet/plugins/klik'

hear (/klik/i) do
  clearance :registered
  description 'Displays how many seconds have elapsed between the last klik.'
  usage 'klik'
  on do
    n = Scarlet::Klik.klik.round(2)
    reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
  end
end

hear (/time(?:\s(\S+))?/i) do
  clearance :registered
  description 'Prints the current owners time.'
  usage 'time'
  on do
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
end

hear (/update(?:\s(\S+))?/i) do
  clearance :dev
  description 'Just to nag the crap out of Speed.'
  usage 'update [<name>]'
  on do
    notice params[1]||"Speed", "%s demandes que tu mettre à jour moi!" % sender.nick
    notify "Notice sent."
  end
end
