require 'scarlet/plugin'
require 'scarlet/helpers/http_helper'
require 'uri'

module Scarlet::Plugins
  # Plugin for printing HTTP(S) link titles.
  class LinkPrinter
    include Scarlet::Plugin
    helper Scarlet::HttpHelper

    on :privmsg do |event|
      params.first.match(/((?:http|https):\/\/[^ ]*)/) do |url|
        uri = URI(url[0])
        html_request(uri.to_s).get(redirects: 1).callback do |http|
          if html = http.response.value.presence
            if title = html.css('title').text.presence
              reply "Title: #{title.strip}"
            end
          end
        end
      end
    end
  end
end
