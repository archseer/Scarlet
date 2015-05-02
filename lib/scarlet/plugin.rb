require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require 'scarlet/listeners'

class Scarlet
  module Helpers
    extend ActiveSupport::Concern

    class_methods do
      def helpers
        @helpers ||= Module.new
      end

      def helper(*args, &block)
        args.each do |mod|
          helpers.module_eval { extend mod }
        end

        helpers.module_eval(&block) if block_given?
      end
    end
  end

  class Context
    def initialize *objs
      @objs = objs
    end

    def method_missing method, *args, &block
      @objs.each do |obj|
        next if !obj.respond_to? method
        return obj.__send__ method, *args, &block
      end
      super
    end
  end

  module Plugin
    extend ActiveSupport::Concern
    include Scarlet::Helpers

    included do
      # ~
    end

    def emit(event)
      event.server.plugins.each do |plug|
        plug.handle event
      end
    end

    # Passes the event on to any event listeners that are listening for this command.
    # All events get passed to the +:all+ listener.
    # @param [Event] event The event that was recieved.
    def handle(event)
      klass = self.class
      puts event.params.inspect
      execute = lambda { |block| Scarlet::Context.new(klass.helpers, event.server).instance_exec(event.dup, &block) }
      klass.__listeners__.each_listener(event.command, &execute)
    end

    class_methods do
      def __listeners__
        @_listeners ||= Listeners.new
      end

      delegate :on, to: :__listeners__
    end
  end

  # Plugin namespace
  module Plugins; end
end
