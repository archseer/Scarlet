require 'yaml'
require 'colorize'
require 'active_support/configurable'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/delegation'
require 'scarlet/plugins/command'
require 'scarlet/plugins/account_notify'
require 'scarlet/logger'
require 'scarlet/git'
require 'scarlet/core_ext/process'

# Our main module, namespacing all of our classes. It is used as a singleton,
# offering a limited few of methods to start or stop Scarlet.
class Scarlet
  include ActiveSupport::Configurable
  class << self
    # Points to the root directory of Scarlet.
    attr_accessor :root
  end

  def initialize
    @started_at = Time.now
    Scarlet.root = File.expand_path '../../', File.dirname(__FILE__)
    Scarlet.config.merge! YAML.load_file("#{Scarlet.root}/config.yml").symbolize_keys
    Scarlet.config.db.symbolize_keys! if Scarlet.config.db

    Dir.chdir Scarlet.root do
      Scarlet::Git.data # cache data for later use
    end

    @servers = {}
    @plugins = []
    use Scarlet::Core
    use Scarlet::Plugins::AccountNotify
    use Scarlet::Plugins::Command
  end

  def self.setup(&block)
    new.setup(&block)
  end

  def self.run(&block)
    new.run(&block)
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
      server = Server.new cfg.merge(server_name: name)
      server.started_at = @started_at
      server.plugins = @plugins
      @servers[name] = server
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

  def stop(status = 0)
    EM.add_timer 0.1 do
      logger.info ">> Shutting down with status: #{status}".light_green
      shutdown
      EM.add_timer 0.1 do
        EM.stop
        exit status
      end
    end
  end

  # Start the EM reactor loop and start Scarlet.
  def run
    return if EM.reactor_running? # Don't start the reactor if it's running!
    logger.info ">> Scarlet v#{Scarlet::VERSION} (development)".light_green

    EventMachine.run do
      yield if block_given?
      start
      trap('INT') { stop }
      trap('TERM') { stop 1 }
      trap('USR2') { stop 15 }
    end
  end
end
