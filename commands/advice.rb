require 'scarlet/helpers/http_helper'
# Ported to ruby for Scarlet from https://github.com/github/hubot-scripts/blob/master/src/scripts/advice.coffee
# Get some valuable advice from adviceslip.com

def all_hope_is_lost
  reply "You're on your own bud."
end

def display_advice(response)
  return all_hope_is_lost if response.blank?

  # usually from a /advice/search
  if slips = response['slips'].presence
    reply slips.sample['advice']
  # usually from an /advice request
  elsif slip = response['slip']
    reply slip['advice']
  # nope mate, can't help ya
  else
    all_hope_is_lost
  end
end

def random_advice
  http = json_request("http://api.adviceslip.com/advice").get
  http.errback { reply 'Error' }
  http.callback do
    display_advice http.response.value
  end
end

hear(/what (?:do you|should I) do (?:when|about) (?<query>.*)/i,
  /how do you handle (?<query>.*)/i,
  /some advice about (?<query>.*)/i,
  /think about (?<query>.*)/i) do
  clearance nil
  description 'Ask about the wonders of the world!'
  helpers Scarlet::HttpHelper
  on do
    query = params[:query]
    http = json_request("http://api.adviceslip.com/advice/search/#{query}").get
    http.errback { reply 'Error' }
    http.callback do
      value = http.response.value.presence
      if value && !value.key?('message')
        display_advice value
      else
        random_advice
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
    random_advice
  end
end
