require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/delegation'
require 'scarlet/fmt'

module Scarlet
  # This wraps our DSL for custom bot commands.
  class Command
    class Loader
      # (see Command.hear)
      def hear *args, &block
        Command.hear *args, &block
      end

      def load_file filename
        instance_eval File.read(filename), filename, 1
      end

      def self.load_file filename
        new.load_file filename
      end
    end

    class Listener
      # @return [Symbol] privelige level required to run command
      attr_accessor :clearance
      # @return [Proc] raw callback block
      attr_accessor :callback
      # @return [String] a desription of the command
      attr_accessor :description
      # @return [String] short usage template
      attr_accessor :usage
      # @return [Regexp] pattern to match the command
      attr_accessor :regex
      # @return [Array<Module>] helpers to extend the callback
      attr_accessor :helpers

      def initialize
        @clearance = :dev
        @callback = nil
        @description = ''
        @usage = ''
        @regex = nil
        @helpers = []
      end

      def help
        if @usage.presence && @description.presence
          "#@usage - #@description"
        elsif @usage.presence
          "#@usage"
        elsif @description.presence
          "#@description"
        else
          ''
        end
      end

      def match str
        str.match @regex
      end

      def invoke event, matches
        Callback.invoke @callback, @helpers, event, matches
      end
    end

    # Class used for building commands, normally a command construct is passed in.
    class Builder
      attr_reader :listener

      def initialize listener
        @listener = listener
      end

      # Strips provided text string, it removes newlines and extra spaces,
      # attemping to make the string as flat as possible
      #
      # @param [String] text
      # @return [String] stripped string
      def strip_text text
        # remove new lines, crunch multiple spaces to single spaces
        text.gsub(/[\n\s]+/, ' ').strip
      end

      # Sets the clearance level
      #
      # @param [Symbol] level
      def clearance level
        @listener.clearance = level
      end

      # Sets the description
      #
      # @param [String] text
      def description text
        @listener.description = strip_text text
      end

      # Sets the usage text
      #
      # @param [String] text
      def usage text
        @listener.usage = strip_text text
      end

      # Extends the callback context
      #
      # @param [Module] modules  a list of modules to extend the callback environment with
      def helpers *modules
        @listener.helpers = modules
      end

      # Sets the callback
      def on &block
        @listener.callback = block
      end
    end

    # A callback instance, which contains a callback command that we can save for
    # later and run it at a later time, when the event listener tied to it matches.
    class Callback
      # Create a new callback instance,
      #
      # @param [Proc] block The block we want to call as a callback.
      def initialize block, helpers
        @block = block
        @helpers = helpers
      end

      # Run our stored callback, passing in the event we captured and the matches
      # from our command.
      #
      # @param [Event] event The event we captured.
      # @param [MatchData] matches The matches we caught when we matched the
      #  callback to the event.
      def invoke event, matches
        @event = event
        @event.params = matches
        begin
          instance_eval &@block
        rescue => ex
          puts ex.inspect
          puts ex.backtrace.join("\n")
          reply "Command Callback error: #{ex.inspect}"
        end
      end

      delegate :msg, :notice, :reply, :action, :send, :send_cmd, to: :@event

      # format module
      def fmt
        Scarlet::Fmt
      end

      # DSL delegator, delegates calls to the helpers or +@event+ to be able to directly use their
      # attributes or methods.
      def method_missing method, *args, &block
        @helpers.each do |helper|
          return helper.__send__ method, *args, &block if helper.respond_to? method
        end
        return @event.__send__ method, *args, &block if @event.respond_to? method
        super
      end

      # Creates and invokes a new Callback context
      #
      # @param [Proc] cb
      # @param [Event] event
      # @param [MatchData] matches
      def self.invoke cb, helpers, event, matches
        new(cb, helpers).invoke event, matches
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
      def filter
        @@filter
      end

      # Registers a new listener for bot commands.
      #
      # @param [Regexp] patterns The regex that should match when we want to trigger our callback.
      # @param [Proc] block The block to execute when the command is used.
      def hear *patterns, &block
        # make a prefab Listener, this will be duplicated for each pattern/regex
        ls = Listener.new.tap { |l| Builder.new(l).instance_eval &block }
        patterns.each do |regex|
          regex = Regexp.new "^#{regex.source}$", regex.options
          @@listeners[regex] = ls.dup.tap { |l| l.regex = regex }
        end
      end

      # Loads a command file from the given path
      #
      # @param [String] path
      def load_command(path)
        puts "Loading command: #{path}"
        Loader.load_file path
      end

      # Loads a command file from the given name.
      def load_command_rel(name)
        load_command File.join(Scarlet.root, 'commands', name)
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

      # Selects all commands which evaluate true in the block.
      #
      # @yieldparam [Listener]
      # @return [Array<Listener>]
      def select_commands
        return to_enum :select_commands unless block_given?
        @@listeners.each_value.select do |l|
          yield l
        end
      end

      # Selects all commands which match the provided command string
      #
      # @param [String] command
      # @return [Array<Listener>]
      def match_commands command
        select_commands { |c| c.usage.start_with? command }
      end

      # Returns help matching the specified string. If no command is used, then
      # returns the entire list of help.
      #
      # @param [String] command The keywords to search for.
      def get_help command = nil
        help = if c = command.presence
          match_commands(c).map &:help
        else
          @@listeners.each_value.map &:help
        end
        # map each by #presence (exposing empty strings),
        # remove all nil entries from presence,
        # make each line unique,
        # and finally sort the result.
        help.map(&:presence).compact.uniq.sort
      end
    end

    # Initialize is here abused to run a new instance of the Command.
    #
    # @param [Event] event The event that was caught by the server.
    def initialize event
      if word = check_filters(event.params.first)
        event.reply "Cannot execute because \"#{word}\" is blocked."
        return
      end

      @@listeners.keys.each do |key|
        key.match event.params.first do |matches|
          if check_access(event, @@listeners[key].clearance)
            @@listeners[key].invoke event.dup, matches
          end
        end
      end
    end

    private # Make the checks private.

    # Runs the command trough a filter to check whether any of the words
    # it uses are disallowed.
    # @param [String] params The parameters to check for censored words.
    def check_filters params
      return false if @@filter.empty? or params.start_with?("unfilter")
      return Regexp.new("(#{@@filter.join("|")})").match params
    end

    # Checks whether the user actually has access to the command and can use it.
    # @param [Event] event The event that was recieved.
    # @param [Symbol] privilege The privilege level required for the command.
    # @return [Boolean] True if access is allowed, else false.
    def check_access event, privilege
      nick = Scarlet::Nick.first nick: event.sender.nick
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

    # @return [Boolean] true if user is banned, else false.
    def check_ban event
      ban = Scarlet::Ban.first nick: event.sender.nick
      if ban and ban.level > 0 and ban.servers.include?(event.server.config.address)
        event.reply "#{event.sender.nick} is banned and cannot use any commands."
        return true
      end
      return false
    end
  end
end
