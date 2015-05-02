require 'set'

class Scarlet
  class Listeners
    def initialize
      @listeners = {}
    end

    def on command, *args, &block
      listeners = @listeners[command] ||= []
      block ||= proc { nil }
      args.include?(:prepend) ? listeners.unshift(block) : listeners.push(block)
    end

    def each_listener_of key
      (@listeners[key] || []).each do |listener|
        yield listener
      end
    end

    def each_listener key, &block
      each_listener_of :all, &block
      each_listener_of key, &block
    end

    def trigger key, &block
      each_listener key, &block
    end
  end
end
