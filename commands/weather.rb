# encoding: utf-8
# TODO if there are mutliple locations, make the user pick. Forecast for today.

Scarlet.hear /weather in (.+)\s?(?:units)?\s?(.*)?/ do
  units = 'c'
  units = 'c' if params[2] =~ /celsius/i
  units = 'f' if params[2] =~ /farenheit/i

  http = EventMachine::HttpRequest.new('http://xoap.weather.com/search/search').get :query => {'where' => params[1]}

  http.errback { p 'Uh oh error'; }
  http.callback {
    locations = http.response.match(/<loc id="(.+)" type="1">(.+)<\/loc>/)

    if locations && locations[1]
      request = EventMachine::HttpRequest.new('http://weather.yahooapis.com/forecastjson').get :query => {'p' => locations[1], 'u' => units}
      request.callback {
        h = JSON.parse(request.response)
        r = "Currently in #{locations[2]} it is #{h["condition"]["text"].downcase} #{h["condition"]["temperature"]}°#{h["units"]["temperature"]} wind is #{h["wind"]["speed"]}#{h["units"]["speed"]} from #{h["wind"]["direction"]} with a humidity of #{h["atmosphere"]["humidity"]}%, visibility #{h["atmosphere"]["visibility"]}% and a #{h["atmosphere"]["rising"]} pressure of #{h["atmosphere"]["pressure"]}#{h["units"]["pressure"]}."
        msg return_path, r
      }
    else
      msg return_path, "There was a problem with the location..."
    end
  }
end
