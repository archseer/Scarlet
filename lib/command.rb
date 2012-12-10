# encoding: utf-8
module Scarlet
class Command
  @@listens = {}
  @@help = []
  @@filter = []
  @@clearance = {any: 0, registered: 1, voice: 2, vip: 3, super_tester: 6, op: 7, dev: 8, owner: 9}

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
        next if line.include? 'encoding'
        next unless line.include? '-'
        @@help << line[2..line.length].strip
      end
    end

    # Returns help matching the specified string. If no command is used, then
    # returns the entire list of help.
    def get_help command=nil
      return @@help.sort unless command
      regex = Regexp.new command, Regexp::IGNORECASE
      return @@help.select {|h| h.match regex}.sort
    end

    def filter
      @@filter
    end
  end

  # Initialize is here abused to run a new instance of the Command. 
  def initialize event
    if word = check_filters(event.params.first)
      event.reply "Cannot execute because \"#{word}\" is blocked."
      return
    end

    @@listens.keys.each do |key|
      key.match(event.params.first) {|matches|
        @@listens[key][:callback].run event.dup, matches if check_access(event, @@listens[key][:clearance])
      }
    end
  end

  # Runs the command trough a filter to check whether any of the words
  # it uses are disallowed.
  def check_filters params
    return false if @@filter.empty? or params.start_with?("unfilter")
    return Regexp.new("(#{@@filter.join("|")})").match(params)
  end

  def check_access event, privilege
    nick = Scarlet::Nick.first(:nick => event.sender.nick)
    ban = Scarlet::Ban.first(:nick => nick.nick) if nick
    if ban and ban.level > 0 and ban.servers.include?(event.server.config.address)
      event.reply "#{event.sender.nick} is banned and cannot use any commands."
      return false
    end
    return true if @@clearance[privilege] == 0 # if it doesn't need clearance (:any)
    if event.server.users.get(event.sender.nick).ns_login # check login
      if !nick
        event.reply "Registration not found, please register."
        return false
      elsif nick.privileges < @@clearance[privilege]
        event.reply "Your security clearance does not grant access."
        return false
      end
    else
      event.reply "Test subject #{event.sender.nick} is not logged in with NickServ."
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

    delegate :msg, :notice, :reply, :action, :send, :send_cmd, to: :@event

    # DSL delegator, no need to use @event to access it's methods
    def method_missing method, *args
      return @event.__send__ method, *args if @event.respond_to? method
      super
    end

    def context_nick nick
      case nick.downcase
      when "you"; server.current_nick
      when "me" ; sender.nick
      else      ; nick
      end
    end
    
  end
end
end