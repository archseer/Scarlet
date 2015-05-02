require 'chronic'

hear (/set(?:\s+my)?\s+timezone\s+(?<timezone>.+)/i) do
  clearance :registered
  description 'self-explanatory; used with time command'
  usage 'set timezone <timezone>'
  on do
    timezone = params[:timezone]
    if nick = Scarlet::Nick.first(nick: sender.nick)
      if TZInfo::Timezone.all_identifiers.include?(timezone)
        nick.settings[:timezone] = timezone
        nick.save!
        notify "Your current Time Zone is: %s" % nick.settings[:timezone]
      else
        notify "Invalid Time Zone: %s" % timezone
      end
    else
      notify "You cannot access account settings, are you logged in?"
    end
  end
end

hear (/time(?:\s+(?<nick>\S+))?/i) do
  clearance :registered
  description 'Prints user time'
  usage 'time [<nick>]'
  on do
    nick = params[:nick]
    if nick
      nck = params[1].gsub(/-me/i, sender.nick)
      if nick = Scarlet::Nick.first(:nick => nck)
        if zone_str = nick.settings[:timezone]
          reply Time.now.in_time_zone(zone_str)
        else
          reply 'Your timezone is not set: Use !set timezone <your_timezone_string>'
        end
      else
        reply 'Cannot view time for "%s".' % params[1]
      end
    else
      reply Scarlet::Fmt.time(Time.now)
    end
  end
end

hear (/timeq\s+(?<query>.+)/) do
  clearance :any
  description ''
  usage 'timeq <query>'
  on do
    if query = params[:query].presence
      if r = Chronic.parse(query)
        reply Scarlet::Fmt.time(r)
      else
        reply 'Ask Doctor Who.'
      end
    else
      reply 'Invalid time query string!'
    end
  end
end
