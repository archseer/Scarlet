require 'scarlet/helpers/http_command_helper'
# Ported to ruby for Scarlet from https://github.com/github/hubot-scripts/blob/master/src/scripts/advice.coffee
# Get some valuable advice from adviceslip.com

all_hope_is_lost = lambda { |c| c.reply "You're on your own bud." }
display_advice = lambda do |c, response|
  # usually from a /advice/search
  if slips = response['slips'].presence
    c.reply slips.sample['advice']
  # usually from an /advice request
  elsif slip = response['slip']
    c.reply slip['advice']
  # nope mate, can't help ya
  else
    all_hope_is_lost.call c
  end
end

random_advice = lambda do |c|
  http = c.json_request("http://api.adviceslip.com/advice").get
  http.errback { reply 'Error' }
  http.callback do
    display_advice.call c, http.response
  end
end

hear (/what (?:do you|should I) do (?:when|about) (?<query>.*)/i),
  (/how do you handle (?<query>.*)/i),
  (/some advice about (?<query>.*)/i),
  (/think about (?<query>.*)/i) do
  clearance :any
  description 'Ask about the wonders of the world!'
  helpers Scarlet::HttpCommandHelper
  on do
    query = params[:query]
    http = json_request("http://api.adviceslip.com/advice/search/#{query}").get
    http.errback { reply 'Error' }
    http.callback do
      if http.response.blank?
        random_advice.call self
      else
        display_advice.call self, http.response
      end
    end
  end
end

hear (/advice/i) do
  clearance :any
  description 'Ask for random advice.'
  usage 'advice'
  helpers Scarlet::HttpCommandHelper
  on do
    random_advice.call self
  end
end
