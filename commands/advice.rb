require 'scarlet/helpers/http_helper'
# Ported to ruby for Scarlet from https://github.com/github/hubot-scripts/blob/master/src/scripts/advice.coffee
# Get some valuable advice from adviceslip.com

all_hope_is_lost = lambda { reply "You're on your own bud." }

display_advice = lambda do |response|
  return instance_exec(&all_hope_is_lost) if response.blank?
  # usually from a /advice/search
  if slips = response['slips'].presence
    reply slips.sample['advice']
  # usually from an /advice request
  elsif slip = response['slip']
    reply slip['advice']
  # nope mate, can't help ya
  else
    instance_exec(&all_hope_is_lost)
  end
end

random_advice = lambda do
  http = json_request("http://api.adviceslip.com/advice").get
  http.errback { reply 'Error' }
  http.callback do
    instance_exec(http.response.value, &display_advice)
  end
end

hear(/what (?:do you|should I) do (?:when|about) (?<query>.*)/i,
  /how do you handle (?<query>.*)/i,
  /some advice about (?<query>.*)/i,
  /think about (?<query>.*)/i) do
  clearance nil
  description 'Ask about the wonders of the world!'
  usage 'what (do you|should I) do (when|about) <query>'
  helpers Scarlet::HttpHelper
  on do
    query = params[:query]
    http = json_request("http://api.adviceslip.com/advice/search/#{query}").get
    http.errback { reply 'Error' }
    http.callback do
      value = http.response.value.presence
      if value && !value.key?('message')
        instance_exec(value, &display_advice)
      else
        instance_exec(&random_advice)
      end
    end
  end
end

hear(/advice/i) do
  clearance nil
  description 'Ask for random advice.'
  usage 'advice'
  helpers Scarlet::HttpHelper
  on do
    instance_exec(&random_advice)
  end
end
