# encoding: utf-8

# weather in <location> units <unit> - Displays the current weather stats for <location> in <units>.
Scarlet.hear /weather in (.+?)(?:\s*units\s*(.*))?\s*$/ do
  units = 'c'
  units = 'c' if params[2] =~ /celsius/i
  units = 'f' if params[2] =~ /fahrenheit/i

  http = EventMachine::HttpRequest.new('http://xoap.weather.com/search/search').get :query => {'where' => params[1]}

  http.errback { reply "ERROR! Fatal mistake." }
  http.callback {
    locations = http.response.match(/<loc id="(.+)" type="1">(.+)<\/loc>/)
    if locations && locations[1]
      request = EventMachine::HttpRequest.new('http://weather.yahooapis.com/forecastjson').get :query => {'p' => locations[1], 'u' => units}
      request.callback {
        h = JSON.parse(request.response)
        location = locations[2].end_with?(", ") ? locations[2].chop.chop : locations[2]
        condition = h["condition"]["text"].downcase
        condition_description = condition.end_with?("s") ? "there are" : "it is"
        condition_description = "there is a" if condition.end_with?("shower")
        condition_description = "there is" if condition.end_with?("rain")
        h["atmosphere"]["visibility"] = "unknown" if h["atmosphere"]["visibility"].blank?
        h["atmosphere"]["humidity"] = "unknown" if h["atmosphere"]["humidity"].blank?
        r = []
        r << "Currently in #{location} #{condition_description} #{condition}"
        r << "#{h["condition"]["temperature"].to_i}°#{h["units"]["temperature"]},"
        r << "winds from #{h["wind"]["direction"]} at #{h["wind"]["speed"].to_i} #{h["units"]["speed"]}."
        r << "#{h["atmosphere"]["humidity"]}% humidity, #{h["atmosphere"]["visibility"]} #{h["units"]["distance"]} visibility"
        r << "and a #{h["atmosphere"]["rising"]} pressure of #{h["atmosphere"]["pressure"].to_i} #{h["units"]["pressure"]}."
        reply r.join(' ')
      }
    else
      reply "There was a problem with the location..."
    end
  }
end
