require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/delegation'
require 'scarlet/fmt'
require 'scarlet/logger'

class Scarlet
  # This wraps our DSL for custom bot commands.
  class Command
    class Loader
      def initialize plugin
        @command = plugin
      end
      # (see Command.hear)
      def hear *args, &block
        @command.hear *args, &block
      end

      def load_file filename
        instance_eval File.read(filename), filename, 1
      end
    end

    class Listener
      # @return [Proc] clearance filter function
      attr_accessor :clearance
      # @return [Proc] raw callback block
      attr_accessor :callback
      # @return [String] a desription of the command
      attr_accessor :description
      # @return [String] short usage template
      attr_accessor :usage
      # @return [Array<Module>] helpers to extend the callback
      attr_accessor :helpers

      def initialize
        # allow registered users to access the command by default
        @clearance = proc { |_| true }
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
      private def strip_text text
        # remove new lines, crunch multiple spaces to single spaces
        text.gsub(/[\n\s]+/, ' ').strip
      end

      # Sets the command clearance filter, setting clearance to nil is equivalent
      # to saying "anyone may use this command", while setting it to
      # proc { |user| true } will say "only registerd users may use this"
      #
      # @param [Proc] func
      # @yieldparam [Nick] user
      def clearance func = nil, &block
        @listener.clearance = func || block
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
      def on func = nil, &block
        @listener.callback = func || block
      end
    end

    # A callback instance, which contains a callback command that we can save for
    # later and run it at a later time, when the event listener tied to it matches.
    class Callback
      include Scarlet::Loggable

      # @return [Scarlet::Event]
      attr_reader :event

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
          instance_exec self, &@block
        rescue => ex
          logger.error ex.inspect
          logger.error ex.backtrace.join("\n")
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

  end
end
