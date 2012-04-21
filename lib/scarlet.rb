class Scarlet
  @@listens = {}
  @@clearance = {:any => 0, :registered => 1, :voice => 2, :vip => 3, :super_tester => 6, :op => 7, :dev => 8, :owner => 9}
      
  class << self
    def hear regex, clearance=nil, &block
      @@listens[regex] ||= {}
      @@listens[regex][:clearance] = (clearance || :any)
      @@listens[regex][:callback] = Callback.new(block)
    end
  end

  def initialize server, event
    event.server = server
    event.params[0] = event.params[0].split(' ').drop(1).join(' ')
    @@listens.keys.each {|key|
      if matches = key.match(event.params.first)
        @@listens[key][:callback].run event.dup, matches if check_access(event, @@listens[key][:clearance])
      end
    }
  end

  def check_access event, privilege
    if ::IrcBot::User.ns_login? event.server.channels, event.sender.nick # check login
      nick = ::IrcBot::Nick.where(:nick => event.sender.nick)
      if nick.count == 0
        event.server.msg event.return_path, "Registration not found, please register."
        return false
      elsif nick.first.privileges < @@clearance[privilege]
        event.server.msg event.return_path, "Your security clearance does not grant access."
        return false
      else
        return true
      end
    else
      event.server.msg event.return_path, "Test subject is not logged in with NickServ."
      return false
    end
  end

  class Callback
    def initialize block
      @block = block
    end

    def run event, matches
      @event = event
      @event.params = matches
      self.instance_eval &@block
    end

    def msg target, message, silent=false
      server.msg(target, message, silent)
    end

    def notice target, message, silent=false
      server.notice(target, message, silent)
    end

    def send string
      server.send string
    end

    def send_cmd cmd, hash
      server.send_cmd cmd, hash
    end

    def method_missing(method, *args)
      return @event.send(method, *args) if @event.respond_to?(method)
      #return @event.server.send(method, *args) if @event.server.respond_to?(method)
      super
    end
  end

end

# Quick explanation: inside 'hear' blocks, you can use any of server's send commands
# (msg, notice, send, send_cmd). Also, you have full access to @event's variables
# even more, you can (and should) omit the '@event' and just use the vars directly.
# (i.e. @event.sender.nick => sender.nick,).

# params is a MatchData object. params or params[0] will return the full string.
# params[n] will return n-th match capture.

# return_path is a preset for sending a message back where it came from, either
# a channel or a private message.

# Do it. For science.

Scarlet.hear (/give me (:?a\s)cookie/) do
  msg return_path, "\x01ACTION gives #{sender.nick} a cookie!\x01"
end

Scarlet.hear (/give me (:?a\s)potato/), :dev do
  msg return_path, "\x01ACTION gives #{sender.nick} a potato!\x01"
end