module Scarlet
  module Plugin
    def join listeners
      plugin = self
      listeners.on event_name do |event|
        plugin.invoke event
      end
    end
  end
end
