require 'scarlet/plugins/plugin'

module ScarletPlugin
  class LinkPrinter
    include Scarlet::Plugin

    def event_name
      :privmsg
    end

    def invoke(event)
      # check for http:// URL's and output their titles (TO IMPROVE!)
      event.params.first.match(/((?:http|https):\/\/[^ ]*)/) do |url|
        begin
          EM::HttpRequest.new(url).get(:redirects => 1).callback do |http|
            http.response.match(/<title>(.*)<\/title>/) do |title|
              event.reply "Title: #{title[1]}" #(domain)
            end
          end
        rescue Exception
        end
      end
    end
  end
end
