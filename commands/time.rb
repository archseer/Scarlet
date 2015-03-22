hear (/set(?:\s+my)?\s+timezone\s+(.+)/i) do
  clearance :registered
  description 'self-explanatory; used with time command'
  usage 'set timezone <timezone>'
  on do
    if nick = Scarlet::Nick.first(:nick => sender.nick)
      if TZInfo::Timezone.all_identifiers.include? params[1]
        nick.settings[:timezone] = params[1]
        notify "Your current Time Zone is: %s" % nick.settings[:timezone]
      else
        notify "Invalid Time Zone: %s" % params[1]
      end
    else
      notify "You cannot access account settings, are you logged in?"
    end
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
