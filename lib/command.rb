# encoding: utf-8
module Scarlet
class Command
  @@listens = {}
  @@help = []
  @@filter = []
  @@clearance = {:any => 0, :registered => 1, :voice => 2, :vip => 3, :super_tester => 6, :op => 7, :dev => 8, :owner => 9}
      
  class << self
    def hear regex, clearance=nil, &block
      regex = Regexp.new("^#{regex.source}$", regex.options)
      @@listens[regex] ||= {}
      @@listens[regex][:clearance] = (clearance || :any)
      @@listens[regex][:callback] = Callback.new(block)
    end

    def parse_help file
      File.readlines(file).each do |line|
        next unless line[0] == '#'
        next if line.match 'encoding'
        next unless line.match '-'
        @@help << line[2..line.length].strip
      end
    end

    def get_help command=nil
      return @@help.sort unless command
      regex = Regexp.new command, Regexp::IGNORECASE
      return @@help.select {|h| h.match regex}.sort
    end

    def filter
      @@filter
    end
  end

  def initialize server, event
    event.server = server
    if event.params[0].split(' ')[0] =~ /#{$config.irc_bot.nick}[:,]?\s*/i
      event.params[0] = event.params[0].split(' ').drop(1).join(' ')
    elsif event.params[0].start_with? "!" #control char
      event.params[0].slice!(0)
    end
    
    if !@@filter.empty? and !event.params[0].start_with?("unfilter") and word = compile_filter.match(event.params[0])
      event.server.msg event.return_path, "Cannot execute because \"#{word}\" is blocked."
      return
    end

    @@listens.keys.each {|key|
      if matches = key.match(event.params.first)
        @@listens[key][:callback].run event.dup, matches if check_access(event, @@listens[key][:clearance])
      end
    }
  end

  def compile_filter
    Regexp.new "(#{@@filter.join("|")})"
  end

  def check_access event, privilege
    nck = Scarlet::Nick.where(:nick=>event.sender.nick).first
    ban = (Scarlet::Ban.where(:nick=>nck.nick) or [nil]).first
    if ban and ban.level > 0
      event.server.msg event.return_path, "#{event.sender.nick} is banned and cannot use any commands."
      return false
    end
    return true if @@clearance[privilege] == 0 # if it doesn't need clearance (:any)
    if User.ns_login? event.server.channels, event.sender.nick # check login
      nick = Nick.where(:nick => event.sender.nick)
      if nick.count == 0
        event.server.msg event.return_path, "Registration not found, please register."
        return false
      elsif nick.first.privileges < @@clearance[privilege]
        event.server.msg event.return_path, "Your security clearance does not grant access."
        return false
      end
    else
      event.server.msg event.return_path, "Test subject #{event.sender.nick} is not logged in with NickServ."
      return false
    end
    return true
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

    def reply message, silent=false
      server.msg(return_path, message, silent)
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
end