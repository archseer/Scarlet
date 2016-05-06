require 'fileutils'
require 'yaml'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/delegation'
require 'scarlet/fmt'
require 'scarlet/logger'
require 'scarlet/helpers/nick_helper'

class Scarlet
  # This wraps our DSL for custom bot commands.
  class Command
    class Loader
      def initialize plugin
        @command = plugin
      end

      # @param [String] filename - name of config file to load
      def load_config_file(filename = nil)
        filename ||= Scarlet.root.join('config/commands',
          File.basename(@__file__, File.extname(@__file__)) + '.yml')
        if File.exists?(filename)
          YAML.load_file(filename)
        else
          if block_given?
            yield.tap do |d|
              FileUtils.mkdir_p File.dirname(filename)
              File.write(filename, d.to_yaml)
            end
          end
        end
      end

      # (see Command.hear)
      def hear *args, &block
        @command.hear *args, &block
      end

      def load_file filename
        @__file__ = filename
        instance_eval File.read(filename), filename, 1
      end
    end

    module CommandHelper
      def error_reply(msg)
        reply msg
        throw :abort
      end

      def error_notify(msg)
        notify msg
        throw :abort
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
        @helpers = [Scarlet::BaseHelper, NickHelper, CommandHelper]
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

      def context
        @_cxt ||= Class.new(Scarlet::Context).include(*@helpers)
      end

      def invoke event, matches
        e = event.dup
        e.params = matches
        context.new(e).exec(&@callback)
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
        @listener.helpers.concat modules
      end

      # Sets the callback
      def on func = nil, &block
        @listener.callback = func || block
      end
    end

  end
end
