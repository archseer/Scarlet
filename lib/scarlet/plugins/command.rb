require 'scarlet/plugin'

module Scarlet::Plugins
  class Command
    include Scarlet::Plugin

    def initialize
      Scarlet::Command.load_commands
    end

    on :privmsg do |event|
      # if we detect a command sequence, we remove the prefix and execute it.
      # it is prefixed with config.control_char or by mentioning the bot's current nickname
      if event.params.first =~ /^#{event.server.current_nick}[:,]?\s*/i
        event.params[0] = event.params[0].split[1..-1].join(' ')
        Scarlet::Command.new(event.dup)
      elsif event.params.first.starts_with? config.control_char
        event.params.first.slice!(0)
        Scarlet::Command.new(event.dup)
      end
    end
  end
end
