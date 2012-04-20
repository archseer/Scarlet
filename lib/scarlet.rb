class Scarlet
  @@listens = {}
  class << self
    def hear regex, &block
      @@listens[regex] = Callback.new(block)
    end
  end

  def initialize server, event
    event.server = server
    event.params[0] = event.params[0].split(' ').drop(1).join(' ')
    @@listens.keys.each {|key| 
      if matches = key.match(event.params.first)
        @@listens[key].run event, matches
      end
    }
  end

  class Callback
    def initialize block
      @block = block
    end

    def run event, matches
      @event = event
      @event.matches = matches
      self.instance_eval &@block
    end

    def msg target, message, silent=false
      @event.server.msg(target, message, silent)
    end

    def notice target, message, silent=false
      @event.server.notice(target, message, silent)
    end

    def send string
      @event.server.send string
    end

    def send_cmd cmd, hash
      @event.server.send_cmd cmd, hash
    end

    def method_missing(method, *args)
      return @event.send(method, *args) if @event.respond_to?(method)
      super
    end
  end

end

# Do it. For science.

Scarlet.hear (/give me (:?a\s)cookie/) do
  targ = target == $config.irc_bot.nick ? sender.nick : target
  msg targ, "\x01ACTION gives #{sender.nick} a cookie!\x01"
end