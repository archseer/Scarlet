require 'scarlet/plugins/plugin'
require 'scarlet/helpers/http_helper'
require 'uri'

module ScarletPlugin
  # Plugin for priting HTTP/S links
  class LinkPrinter
    include Scarlet::HttpHelper
    include Scarlet::Plugin

    # @param [Symbol]
    def event_name
      :privmsg
    end

    # @param [Scarlet::Event] event
    def invoke event
      event.params.first.match(/((?:http|https):\/\/[^ ]*)/) do |url|
        begin
          uri = URI(url[0])
          html_request(uri.to_s).get(redirects: 1).callback do |http|
            if html = http.response.value.presence
              if title = html.css('title').text.presence
                event.reply "Title: #{title.strip}"
              end
            end
          end
        rescue Exception => ex
          STDERR.puts 'LinkPrinter error:'
          STDERR.puts ex.inspect
          STDERR.puts ex.backtrace.join("\n")
        end
      end
    end
  end
end
