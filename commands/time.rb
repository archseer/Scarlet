require 'chronic'

hear (/set(?:\s+my)?\s+timezone\s+(?<timezone>.+)/i) do
  clearance :registered
  description 'Sets your timezone. (used with "time for" command)'
  usage 'set [my] timezone <timezone>'
  on do
    timezone = params[:timezone]
    if nick = Scarlet::Nick.first(nick: sender.nick)
      if TZInfo::Timezone.all_identifiers.include?(timezone)
        nick.settings[:timezone] = timezone
        nick.save
        notify "Your current Time Zone is: %s" % nick.settings[:timezone]
      else
        notify "Invalid Time Zone: %s" % timezone
      end
    else
      notify "You cannot access account settings, are you logged in?"
    end
  end
end

hear (/time for\s+(?<nick>\S+)/i) do
  clearance :any
  description 'Displays the time for s specified user by nick.'
  usage 'time for <nick>'
  on do
    nickname = params[:nick].gsub(/\:me/i, sender.nick)
    if nick = Scarlet::Nick.first(nick: nickname)
      if zone_str = nick.settings[:timezone]
        reply Scarlet::Fmt.time(Time.now.in_time_zone(zone_str))
      else
        notify "#{nick.nick} has not set his or her timezone."
      end
    else
      notify 'Cannot view time for "%s".' % params[1]
    end
  end
end

hear (/time query\s+(?:(?<query_tz>.+)\s+\:in\s+(?<timezone>.+)|(?<query>.+))/) do
  clearance :any
  description 'Calculates time using natural language parsing and optionally a timezone.'
  usage 'time query <query> [:in <timezone>]'
  on do
    if query = (params[:query] || params[:query_tz]).presence
      tz = params[:timezone].presence
      r = Chronic.parse(query)
      if r && tz
        reply "#{query} in #{tz} is #{Scarlet::Fmt.time(r.in_time_zone(tz))}"
      elsif r
        reply "#{query} is #{Scarlet::Fmt.time(r)}"
      else
        reply 'Ask Doctor Who.'
      end
    else
      notify 'Invalid time query string!'
    end
  end
end

hear (/time(\s+in\s+(?<timezone>.+))?/) do
  clearance :any
  description 'Returns the time for a specified timezone, else returns the bot\'s local time'
  usage 'time [in <timezone>]'
  on do
    if (tz_name = params[:timezone].presence)
      if tz = Time.find_zone(tz_name)
        reply Scarlet::Fmt.time(Time.now.in_time_zone(tz))
      else
        notify "Could not find timezone #{tz_name}"
      end
    else
      reply Scarlet::Fmt.time(Time.now.in_time_zone(tz))
    end
  end
end
