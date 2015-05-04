require 'scarlet/plugin'

module Scarlet::Plugins
  class Autoname
    include Scarlet::Plugin

    on :quit do |event|
      my_nick = event.server.config.nick
      current_nick = event.server.current_nick
      sender_nick = event.sender.nick
      # if the my current nick is equal to the one from the config
      unless current_nick == my_nick
        # if we're quitting we can just skip as well
        unless sender_nick == current_nick
          # ignore if the quitter isn't who we want
          unless sender_nick != my_nick
            event.send "NICK #{my_nick}"
          end
        end
      end
    end
  end
end
