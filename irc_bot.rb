# IRCBot! Currently one channel based.
# uses mustache templating and blank?
# errors - light_red, info - light_blue, success - light_green
require 'mustache'

module IrcBot
  @commands = {}
  @config = {}
  class << self
    attr_accessor :commands, :config

    def loaded
      $config[:irc_bot] = YAML.load_file("#{File.expand_path File.dirname(__FILE__)}/config.yml").symbolize_keys!
      $config[:irc_bot][:modes].symbolize_values!
      @@bot = EventMachine::connect $config[:irc_bot][:server], $config[:irc_bot][:port], Bot
      puts 'IRC Bot has started.'.green
    end

    def unload
      @@bot.disconnecting = true
      @@bot.client_command :quit, :quit => $config[:irc_bot][:quit]
      @@bot.scheduler.remove_all
    end
  end
  Commands = ::IrcBot.commands
end

base_path = File.expand_path File.dirname(__FILE__)
Modules.load_models base_path
Modules.load_libs base_path