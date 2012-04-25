# IRCBot! Currently one channel based.
# uses mustache templating and blank?
# errors - light_red, info - light_blue, success - light_green
require 'mustache'

class Hash # instead of hash[:key][:key], hash.key.key
  def method_missing(method, *params)
    return self[method.to_s] if self.keys.collect {|key| key}.include?(method.to_s)
    return self[method.to_sym] if self.keys.collect {|key| key}.include?(method.to_sym)
    super
  end
end

module IrcBot
  @commands = {}
  @config = {}
  class << self
    attr_accessor :commands, :config

    def loaded
      $config[:irc_bot] = YAML.load_file("#{File.expand_path File.dirname(__FILE__)}/config.yml").symbolize_keys!
      $config.irc_bot.modes.symbolize_values!
      @@bot = EventMachine::connect $config.irc_bot.server, $config.irc_bot.port, Bot
      puts 'IRC Bot has started.'.green
    end

    def unload
      @@bot.send_cmd :quit, :quit => $config.irc_bot.quit
      @@bot.disconnecting = true
      @@bot.close_connection_after_writing
      @@bot.scheduler.remove_all
    end

    def load_commands root
        Dir["#{root}/commands/**/*.rb"].each {|path| load path }
    end
  end
  Commands = ::IrcBot.commands
end

base_path = File.expand_path File.dirname(__FILE__)
Modules.load_models base_path
Modules.load_libs base_path
Dir["#{base_path}/commands/**/*.rb"].each {|path| 
  load path 
  Scarlet.parse_help path
}