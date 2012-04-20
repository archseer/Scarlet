class Scarlet
  @@listens = {}
  class << self
    def hear (regex, &block)
      @@listens[regex] = block
    end
  end

  def initialize server, event
    event.params[0] = event.params[0].split(' ').drop(1).join(' ')
    @@listens.keys.each {|key| 
      if matches = key.match(event.params.first)
        server.instance_exec event, matches, &@@listens[key]
      end
    }
  end
end

Scarlet.hear (/give me (:?a\s)cookie/) do |event,matches|
  target = event.target == $config.irc_bot.nick ? event.sender.nick : event.target
  msg target, "\x01ACTION gives #{event.sender.nick} a cookie!\x01"
end