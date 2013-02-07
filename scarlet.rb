module Scarlet; end
base_path = File.expand_path File.dirname(__FILE__)
Modules.load_models base_path
Modules.load_libs base_path

# Our main module, namespacing all of our classes. It is used as a singleton,
# offering a limited few of methods to start or stop Scarlet.
module Scarlet
  include ActiveSupport::Configurable
  @@servers = {}
  class << self
    # Points to the root directory of Scarlet.
    attr_reader :root

    # Starts up Scarlet, setting the basic variables and opening connections to servers.
    def start!
      @root = File.expand_path File.dirname(__FILE__)
      Scarlet.config.merge! YAML.load_file("#{Scarlet.root}/config.yml").symbolize_keys
      # create servers
      Scarlet.config.servers.each do |name, cfg|
        cfg[:server_name] = name
        @@servers[name] = Server.new cfg
      end
      # for safety delete the servers list after it gets loaded
      Scarlet.config.delete :servers
      Command.load_commands
    end

    # Shuts down Scarlet. Disconnects from all servers and removes any scheduled tasks.
    def shutdown
      @@servers.values.each do |server|
        server.disconnect
        server.scheduler.remove_all
      end
    end

    # Delegate to Command. (Scarlet.hear is more expressive than Command.hear)
    delegate :hear, to: 'Scarlet::Command'
  end
end