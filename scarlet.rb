# Scarlet - an IRC bot which is slowly becoming an automated assistant framework
# Goal: Make it adapter based and not limited to a protocol.
#----------------------------------------------------------------
# errors - light_red, info - light_blue, success - light_green
require 'mustache'

module Scarlet; end # Stub class so we can safely load in files
base_path = File.expand_path File.dirname(__FILE__)
Modules.load_models base_path
Modules.load_libs base_path

module Scarlet
  @@servers = {}
  class << self
    attr_accessor :config, :root

    def loaded
      Scarlet.root = File.expand_path File.dirname(__FILE__)
      Scarlet.config = YAML.load_file("#{Scarlet.root}/config.yml").symbolize_keys!
      # create servers
      Scarlet.config.servers.each do |name, cfg|
        cfg[:server_name] = name
        @@servers[name] = Server.new cfg
      end
      # for safety delete the servers list after it gets loaded
      Scarlet.config.delete :servers
      # connect servers
      @@servers.values.each do |server|
        server.connection = EventMachine::connect(server.config.address, server.config.port, Connection, server)
      end
      Scarlet.load_commands
      puts 'Scarlet process has started.'.green
    end

    def unload
      @@servers.values.each do |server|
        server.disconnect
        server.scheduler.remove_all
      end
    end

    def load_commands # load custom commands
      Dir["#{Scarlet.root}/commands/**/*.rb"].each {|path| load path and Scarlet::Command.parse_help path}
    end

    # DSL delegator to Command. (Scarlet.hear is more expressive than Command.hear)
    def hear regex, clearance=nil, &block
      Command.hear regex, clearance, &block
    end
  end
end