module Scarlet; end # Stub class so we can safely load in files
base_path = File.expand_path File.dirname(__FILE__)
Modules.load_models base_path
Modules.load_libs base_path

module Scarlet
  include ActiveSupport::Configurable
  @@servers = {}
  class << self
    # Points to the root directory of Scarlet.
    attr_accessor :root

    # Starts up Scarlet, setting the basic variables and opening connections to servers.
    def start!
      Scarlet.root = File.expand_path File.dirname(__FILE__)
      Scarlet.config.merge! YAML.load_file("#{Scarlet.root}/config.yml").symbolize_keys
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
    end

    # Shuts down Scarlet. Disconnects from all servers and removes any scheduled tasks.
    def shutdown
      @@servers.values.each do |server|
        server.disconnect
        server.scheduler.remove_all
      end
    end

    # Loads up commands from the /commands directory under the +Scarlet.root+ path.
    def load_commands
      Dir["#{Scarlet.root}/commands/**/*.rb"].each {|path| load path and Command.parse_help path}
    end

    # DSL delegator to Command. (Scarlet.hear is more expressive than Command.hear)
    delegate :hear, to: 'Scarlet::Command'
  end
end