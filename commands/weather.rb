# encoding: utf-8
require 'scarlet/helpers/http_command_helper'

hear (/weather in\s+(?<location>.+)(?:\s+units\s+(?<unit>\S+))?/i) do
  clearance nil
  description 'Displays the current weather stats for <location> in <units>.'
  usage 'weather in <location> units <unit>'
  helpers Scarlet::HttpCommandHelper
  on do
    units = 'c'
    units = 'c' if params[:unit] =~ /celsius/i
    units = 'f' if params[:unit] =~ /fahrenheit/i

    http = xml_request('http://wxdata.weather.com/wxdata/search/search').get query: { 'where' => params[:location] }
    http.errback { reply "ERROR! Fatal mistake." }
    http.callback do
      data = http.response.value
      locations = data.css('search loc')
      loc = locations.first
      if loc
        id = loc['id']
        name = loc.text.strip
        request = json_request('http://weather.yahooapis.com/forecastjson').get query: { 'p' => id, 'u' => units }
        request.errback { reply 'ERROR: could not retrieve forecast.' }
        request.callback do
          if request.response_header.http_status != 200
            reply "Getting forecast failed, please try again later or contact my owner for support."
          else
            if h = request.response.value
              location = name.end_with?(',') ? name.chop : name
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
            else
              reply 'Invalid response data.'
            end
          end
        end
      else
        reply "There was a problem with the location..."
      end
    end
  end
end
