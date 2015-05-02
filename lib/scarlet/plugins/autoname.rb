require 'scarlet/plugins/plugin'

module ScarletPlugin
  class Autoname
    include Scarlet::Plugin

    def event_name
      :quit
    end

    def invoke event
      my_nick = event.server.config.nick
      current_nick = event.server.current_nick
      sender_nick = event.sender.nick
      # if the my current nick is equal to the one from the config
      return if current_nick == my_nick
      # if we're quitting we can just skip as well
      return if sender_nick == current_nick
      # ignore if the quitter isn't who we want
      return if sender_nick != my_nick

      event.send "NICK #{my_nick}"
    end
  end
end
