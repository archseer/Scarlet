require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require 'scarlet/listeners'

module Scarlet
  module Plugin
    extend ActiveSupport::Concern

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
      execute = lambda { |block| event.server.instance_exec(event.dup, &block) }
      self.class.__listeners__.each_listener(event.command, &execute)
    end

    class_methods do
      def __listeners__
        @_listeners ||= Listeners.new
      end

      delegate :on, to: :__listeners__
    end
  end

  module Helpers
    extend ActiveSupport::Concern

    class_methods do
      def helpers
        @helpers ||= Module.new
      end
    end

    def helper(*args, &block)
      args.each do |mod|
        helpers.module_eval { extend mod }
      end

      helpers.module_eval(&block) if block_given?
    end
  end

  class Context
  end
 
  # Plugin namespace
  module Plugins; end
end
