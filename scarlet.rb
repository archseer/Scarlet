require 'bundler/setup'
Bundler.require
require_relative 'scheduler'

module Scarlet; end
# Load models and library files.
Dir["{models,lib}/**/*.rb"].each {|path| require_relative path }

# Our main module, namespacing all of our classes. It is used as a singleton,
# offering a limited few of methods to start or stop Scarlet.
module Scarlet
  include ActiveSupport::Configurable
  @@servers = {}
  class << self
    # Points to the root directory of Scarlet.
    attr_reader :root

    # Starts up Scarlet, setting the basic variables and opening connections to servers.
    # If Scarlet was already started, it just returns.
    def start!
      return if not @@servers.empty?
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

    # Reconnects Scarlet to all servers. It reuses connections instead of reinitializing.
    def reconnect
      @@servers.values.each do |server|
        server.reconnect
      end
    end

    # Restarts Scarlet. It disconnects all servers and reloads them, as well as
    # reloads commands.
    def restart
      shutdown
      @@servers.clear
      start!
    end

    # Start the EM reactor loop and start Scarlet.
    def run!
      return if EM::reactor_running? # Don't start the reactor if it's running!
      puts ">> Scarlet v#{Scarlet::VERSION} (development)".light_green

      EventMachine::run do
        yield if block_given?
        Scarlet.start!
        trap("INT") {
          Scarlet.shutdown
          EM.add_timer(0.1) { EM.stop }
        }
      end
    end

    # Delegate to Command. (Scarlet.hear is more expressive than Command.hear)
    delegate :hear, to: 'Scarlet::Command'

    # Delegate to Handler, more expressive and allows DSL.
    delegate :on, :ctcp, to: 'Scarlet::Handler'
  end
end
