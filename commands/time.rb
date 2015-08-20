require 'chronic'

msg_timezone_not_set = "%<nick>s has not set his or her timezone"
msg_timezone_not_found = "Could not find timezone %<timezone>s"

find_timezone = proc do |timezone|
  Time.find_zone timezone
end

hear(/set(?:\s+my)?\s+timezone\s+(?<timezone>.+)/i) do
  clearance(&:registered?)
  description 'Sets your timezone. (used with "time for" command)'
  usage 'set [my] timezone <timezone>'
  on do
    timezone = params[:timezone]
    with_nick sender.nick do |nick|
      if find_timezone.call(timezone)
        nick.settings[:timezone] = timezone
        nick.save
        notify "Your current Time Zone is: %s" % nick.settings[:timezone]
      else
        notify "Invalid Time Zone: %s" % timezone
      end
    end
  end
end

hear(/timezone\? (?<timezone>.+)/i) do
  clearance nil
  description 'Checks if the given timezone is valid.'
  usage 'timezone? <timezone>'
  on do
    timezone = params[:timezone]
    if find_timezone.call(timezone)
      reply "Yup, there is a %s timezone" % timezone
    else
      reply "No such timezone %s" % timezone
    end
  end
end

hear(/timezone for\s+(?<nick>\S+)/i) do
  clearance nil
  description 'Displays the timezone for a specified user.'
  usage 'timezone for <nick>'
  on do
    with_nick do |nick|
      if zone_str = nick.settings[:timezone]
        reply "Timezone for #{nick.nick} is #{zone_str}"
      else
        reply(msg_timezone_not_set % { nick: nick.nick })
      end
    end
  end
end

hear(/time for\s+(?<nick>\S+)/i) do
  clearance nil
  description 'Displays the time for a specified user.'
  usage 'time for <nick>'
  on do
    with_nick do |nick|
      if zone_str = nick.settings[:timezone]
        reply Scarlet::Fmt.time(Time.now.in_time_zone(zone_str))
      else
        reply(msg_timezone_not_set % { nick: nick.nick })
      end
    end
  end
end

hear(/time query\s+(?:(?<query_tz>.+)\s+\:in\s+(?<timezone>.+)|(?<query>.+))/) do
  clearance nil
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
      reply 'Invalid time query string!'
    end
  end
end

hear(/time(\s+in\s+(?<timezone>.+))?/) do
  clearance nil
  description 'Returns the time for a specified timezone, else returns the bot\'s local time'
  usage 'time [in <timezone>]'
  on do
    if (timezone = params[:timezone].presence)
      if tz = find_timezone.call(timezone)
        reply Scarlet::Fmt.time(Time.now.in_time_zone(tz))
      else
        reply(msg_timezone_not_found % { timezone: timezone })
      end
    else
      reply Scarlet::Fmt.time(Time.now.in_time_zone(timezone))
    end
  end
end
