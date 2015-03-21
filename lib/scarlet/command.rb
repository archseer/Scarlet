require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/delegation'

module Scarlet
  class CommandLoad
    def hear(*args, &block)
      Command.hear(*args, &block)
    end

    def load_file(filename)
      instance_eval File.read(filename), filename, 1
    end

    def self.load_file(filename)
      new.load_file(filename)
    end
  end
  # This wraps our DSL for custom bot commands.
  class Command
    class Listener
      attr_accessor :clearance
      attr_accessor :callback
      attr_accessor :description
      attr_accessor :usage

      def initialize
        @clearance = :dev
        @callback = nil
        @description = ''
        @usage = ''
      end

      def help
        "#@usage - #@description"
      end
    end

    # Class used for building commands, normally a command construct is passed in.
    class CommandBuilder
      attr_reader :listener

      def initialize(listener)
        @listener = listener
        @helpers = []
      end

      # Sets the clearance level
      #
      # @param [Symbol] level
      def clearance(level)
        @listener.clearance = level
      end

      # Sets the description
      #
      # @param [String] text
      def description(text)
        @listener.description = text
      end

      # Sets the usage text
      #
      # @param [String] text
      def usage(text)
        @listener.usage = text
      end

      private def extend_with_helpers
        if c = @listener.callback
          @helpers.each { |mod| c.extend mod }
        end
      end

      # Extends the callback context
      def helpers(*modules)
        @helpers = modules
        extend_with_helpers
      end

      # Sets the callback
      def on(&block)
        @listener.callback = Callback.new(block)
        extend_with_helpers
      end
    end

    # Contains all of our listeners.
    # @return [Hash<Regexp, Listener>]
    @@listeners = {}
    # Any words we want to filter.
    @@filter = []
    # Contains a map of clearance symbols to their numeric equivalents.
    @@clearance = { any: 0, registered: 1, voice: 2, vip: 3, super_tester: 6, op: 7, dev: 8, owner: 9 }

    class << self
      # Registers a new listener for bot commands.
      #
      # @param [Regexp] regex The regex that should match when we want to trigger our callback.
      # @param [Proc] block The block to execute when the command is used.
      def hear(regex, &block)
        regex = Regexp.new("^#{regex.source}$", regex.options)
        @@listeners[regex] = Listener.new.tap { |l| CommandBuilder.new(l).instance_eval(&block) }
      end

      def load_command(path)
        CommandLoad.load_file path
      end

      def load_command_rel(path)
        load_command File.join(Scarlet.root, 'commands', path)
      end

      # Loads (or reloads) commands from the /commands directory under the
      # +Scarlet.root+ path.
      def load_commands
        old_listeners = @@listeners.dup
        @@listeners.clear
        begin
          Dir[File.join(Scarlet.root, 'commands/**/*.rb')].each do |path|
            load_command path
          end
          true
        rescue => ex
          puts ex.inspect
          puts ex.backtrace.join("\n")
          @@listeners.replace old_listeners
          false
        end
      end

      def select_commands
        @@listeners.each_value.select do |l|
          yield l
        end
      end

      def match_commands(command)
        select_commands { |c| command.match c.regex }
      end

      # Returns help matching the specified string. If no command is used, then
      # returns the entire list of help.
      # @param [String] command The keywords to search for.
      def get_help(command = nil)
        return @@listeners.each_value.map(&:help) unless command
        match_commands(command).map(&:help)
      end
    end

    # Initialize is here abused to run a new instance of the Command.
    # @param [Event] event The event that was caught by the server.
    def initialize(event)
      if word = check_filters(event.params.first)
        event.reply "Cannot execute because \"#{word}\" is blocked."
        return
      end

      @@listeners.keys.each do |key|
        key.match(event.params.first) do |matches|
          if check_access(event, @@listeners[key].clearance)
            @@listeners[key].callback.run event.dup, matches
          end
        end
      end
    end

    private # Make the checks private.

    # Runs the command trough a filter to check whether any of the words
    # it uses are disallowed.
    # @param [String] params The parameters to check for censored words.
    def check_filters(params)
      return false if @@filter.empty? or params.start_with?("unfilter")
      return Regexp.new("(#{@@filter.join("|")})").match(params)
    end

    # Checks whether the user actually has access to the command and can use it.
    # @param [Event] event The event that was recieved.
    # @param [Symbol] privilege The privilege level required for the command.
    # @return [Boolean] True if access is allowed, else false.
    def check_access(event, privilege)
      nick = Scarlet::Nick.first(:nick => event.sender.nick)
      return false if check_ban(event) # if the user is banned
      return true if privilege == :any # if it doesn't need clearance (:any)

      if event.server.users.get(event.sender.nick).ns_login # check login
        if !nick # check that user is registered
          event.reply "Registration not found, please register."
          return false
        elsif nick.privileges < @@clearance[privilege]
          event.reply "Your security clearance does not grant access."
          return false
        end
      else
        event.reply "Test subject #{event.sender.nick} is not logged in with NickServ."
        return false
      end
      return true
    end

    # @return [Boolean] True if user is banned, else false.
    def check_ban(event)
      ban = Scarlet::Ban.first(:nick => event.sender.nick)
      if ban and ban.level > 0 and ban.servers.include?(event.server.config.address)
        event.reply "#{event.sender.nick} is banned and cannot use any commands."
        return true
      end
      return false
    end

    # A callback instance, which contains a callback command that we can save for
    # later and run it at a later time, when the event listener tied to it matches.
    class Callback
      # Create a new callback instance,
      # @param [Proc] block The block we want to call as a callback.
      def initialize(block)
        @block = block
      end

      # Run our stored callback, passing in the event we captured and the matches
      # from our command.
      # @param [Event] event The event we captured.
      # @param [MatchData] matches The matches we caught when we matched the
      #  callback to the event.
      def run(event, matches)
        @event = event
        @event.params = matches
        begin
          self.instance_eval &@block
        rescue => ex
          puts ex.inspect
          puts ex.backtrace.join("\n")
          reply "Command Callback error: #{ex.inspect}"
        end
      end

      delegate :msg, :notice, :reply, :action, :send, :send_cmd, to: :@event

      # DSL delegator, delegates calls to +@event+ to be able to directly use it's
      # attributes.
      def method_missing(method, *args)
        return @event.__send__ method, *args if @event.respond_to? method
        super
      end
    end
  end
end
