module Scarlet
  module Plugin
    # define @@listeners = Listeners.new in the included module
  
    # instance methods

    # call listeners for evt
    def trigger evt
    end
    
    # emit a global event
    def emit evt
      #delegate_to event.server
      event.server.emit evt
    end
    def event.server.emit
      plugins.each do |plug|
        plug.trigger evt
      end
    end
    # class methods

    # register listeners
    def on(command, *args, &block)
      @@listeners.on(command, *args, &block)
    end
  end
end

module Scarlet::Plugin
  module Autojoin
    include Scarlet::Plugin
    def print_uri m
      puts m
    end

    on :privmsg do
      url = event.msg.match(URL_REGEX)
      print_uri url if url
    end
  end
end

Scarlet.config do
  use Scarlet::Autojoin
end

use calls Scarlet::Handlers.use
def use plug
  @plugins << plug.new
end

def Scarlet::Handlers.trigger ev
  trigger_own_handles
  @plugins.each do |plug|
    plug.trigger ev
  end
end

# later on, event handles get evald inside a State hash object or POD State object,
# which is serializable to disk.
