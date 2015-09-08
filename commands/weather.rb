# encoding: utf-8
require 'scarlet/helpers/http_helper'

dirs = ["N","NNE","NE","ENE","E","ESE", "SE", "SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"].freeze
url = 'http://api.openweathermap.org/data/2.5/weather'

weather_errors = [
  'A comet struck the weather connection!',
  'Dunno, partially snowy I suppose?',
  'THE SKY IS FALLING!',
  'How am I suppose to know!',
  'There was a problem in getting the weather'
]

hear(/set(?:\s+my)?\s+city\s+(?<city>.+)/i) do
  clearance(&:registered?)
  description 'Sets your city, used for location based commands.'
  usage 'set[ my] city <city>'
  on do
    with_nick sender.nick do |nick|
      nick.update_settings(city: params[:city])
      notify "Your current city is: %s" % nick.settings[:city]
    end
  end
end

# Gracefully stolen from, with some fun stuff thrown in
# https://github.com/skibish/hubot-weather/blob/master/src/hubot-weather.coffee
get_weather = lambda do |location, units|
  http = json_request(url).get query: { q: CGI.escape(location), units: units }
  http.errback { reply "HTTP Error: " + weather_errors.sample }
  http.callback do
    if data = http.response.value
      if msg = data['message']
        reply msg
      else
        weather = data['weather'][0]
        main = data['main']
        wind = data['wind']
        sys = data['sys']

        wind_dir = if wind['deg']
          dirs[((wind['deg'] / 22.5) + 0.5) % dirs.size]
        else
          'UNKNOWN'
        end
        reply "Weather forecast for #{data['name']}, #{sys['country']}: #{weather['description']} #{main['temp']}°C, #{wind_dir} #{wind['speed']} km/h wind, #{main['humidity']}% humidity. [updated #{fmt.short_time(Time.at(data['dt']))}]"
      end
    else
      reply "No data received: " + weather_errors.sample
    end
  end
end

hear(/weather in\s+(?<location>.+)(?:\s+:units\s+(?<units>\S+))?/i) do
  clearance nil
  description 'Displays the current weather stats for <location> in <units>.'
  usage 'weather in <location> [units <unit>]'
  helpers Scarlet::HttpHelper
  on do
    nick = find_nick sender.nick

    location = params[:location].presence || (nick && nick.settings[:city])
    unless location
      if nick && params[0] == 'weather'
        error_reply "You have not set your location"
      else
        error_reply "No location provided"
      end
    end

    units = params[:units].presence || 'metric'
    instance_exec(location, units, &get_weather)
  end
end

get_weather_for = lambda do |user|
  with_nick user do |nick|
    instance_exec(nick.settings[:city], 'metric', &get_weather)
  end
end

hear(/weather for\s+(?<nick>\S+)/i) do
  clearance nil
  description 'Displays your weather forecast for a user'
  usage 'weather for <nick>'
  helpers Scarlet::HttpHelper
  on do
    instance_exec(params[:nick], &get_weather_for)
  end
end

hear(/weather/i) do
  clearance(&:registered?)
  description 'Displays your weather forecast.'
  usage 'weather'
  helpers Scarlet::HttpHelper
  on do
    instance_exec(sender.nick, &get_weather_for)
  end
end
