require 'yaml'
require 'colorize'
require 'active_support/configurable'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/delegation'
require 'scarlet/plugins/command'
require 'scarlet/plugins/link_printer'
require 'scarlet/plugins/autoname'
require 'scarlet/plugins/account_notify'
require 'scarlet/logger'

# Our main module, namespacing all of our classes. It is used as a singleton,
# offering a limited few of methods to start or stop Scarlet.
class Scarlet
  include ActiveSupport::Configurable
  class << self
    # Points to the root directory of Scarlet.
    attr_accessor :root
  end

  def initialize(settings = {})
    settings = OpenStruct.new(settings)

    Scarlet.root = settings.root
    Scarlet.config.merge! YAML.load_file(settings.config).symbolize_keys
    Scarlet.config.db.symbolize_keys! if Scarlet.config.db

    @servers = {}
    @plugins = []
    use Scarlet::Core
    use Scarlet::Plugins::AccountNotify
    use Scarlet::Plugins::Command

    if plugins = Scarlet.config.plugins
      plugins.each do |plugin|
        if const = "Scarlet::Plugins::#{plugin}".safe_constantize
          use const
        else
          puts "No such plugin: #{plugin}"
        end
      end
    end
  end

  def use plugin
    @plugins << plugin.new
  end

  def setup(&block)
    self.instance_exec(&block)
    self
  end

  # Starts up Scarlet, setting the basic variables and opening connections to servers.
  # If Scarlet was already started, it just returns.
  def start
    return unless @servers.empty?
    # create servers
    Scarlet.config.servers.each do |name, cfg|
      @servers[name] = Server.new cfg.merge(server_name: name)
      @servers[name].plugins = @plugins
    end
    # for safety delete the servers list after it gets loaded
    Scarlet.config.delete :servers
  end

  # Shuts down Scarlet. Disconnects from all servers and removes any scheduled tasks.
  def shutdown
    @servers.values.each do |server|
      server.disconnect
      server.scheduler.shutdown
    end
  end

  # Reconnects Scarlet to all servers. It reuses connections instead of reinitializing.
  def reconnect
    @servers.values.each do |server|
      server.reconnect
    end
  end

  # Restarts Scarlet. It disconnects all servers and reloads them, as well as
  # reloads commands.
  def restart
    shutdown
    @servers.clear
    start
  end

  # Start the EM reactor loop and start Scarlet.
  def run
    return if EM.reactor_running? # Don't start the reactor if it's running!
    logger.info ">> Scarlet v#{Scarlet::VERSION} (development)".light_green

    EventMachine.run do
      yield if block_given?
      start
      trap 'INT' do
        shutdown
        EM.add_timer(0.1) { EM.stop }
      end
    end
  end
end
