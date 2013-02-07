# encoding: utf-8
module Scarlet
# This wraps our DSL for custom bot commands.
class Command
  # Contains all of our listeners.
  @@listeners = {}
  # All of our help strings.
  @@help = []
  # Any words we want to filter.
  @@filter = []
  # Contains a map of clearance symbols to their numeric equivalents.
  @@clearance = {any: 0, registered: 1, voice: 2, vip: 3, super_tester: 6, op: 7, dev: 8, owner: 9}

  class << self
    # Registers a new listener for bot commands.
    # @param [Regexp] regex The regex that should match when we want to trigger our callback.
    # @param [Symbol] clearance The clearance level needed to use the command.
    # @param [Proc] block The block to execute when the command is used.
    def hear regex, clearance=:any, &block
      regex = Regexp.new("^#{regex.source}$", regex.options)
      @@listeners[regex] ||= {}
      @@listeners[regex][:clearance] = clearance
      @@listeners[regex][:callback] = Callback.new(block)
    end

    # Loads (or reloads) commands from the /commands directory under the
    # +Scarlet.root+ path.
    def load_commands
      @@listeners.clear
      @@help.clear
      Dir["#{Scarlet.root}/commands/**/*.rb"].each do |path|
        load path
        parse_help path
      end
      return true
    end

    # Parses the help comments from a file.
    # @param [String] file The file from which it should parse help.
    def parse_help file
      File.readlines(file).each do |line|
        next unless line.start_with? '#'
        next if line.include? 'encoding'
        next unless line.include? '-'
        @@help << line[2..line.length].strip
      end
    end

    # Returns help matching the specified string. If no command is used, then
    # returns the entire list of help.
    # @param [String] command The keywords to search for.
    def get_help command=nil
      return @@help.sort unless command
      regex = Regexp.new command, Regexp::IGNORECASE
      return @@help.select {|h| h.match regex}.sort
    end
  end

  # Initialize is here abused to run a new instance of the Command.
  # @param [Event] event The event that was caught by the server.
  def initialize event
    if word = check_filters(event.params.first)
      event.reply "Cannot execute because \"#{word}\" is blocked."
      return
    end

    @@listeners.keys.each do |key|
      key.match(event.params.first) {|matches|
        @@listeners[key][:callback].run event.dup, matches if check_access(event, @@listeners[key][:clearance])
      }
    end
  end

  # Runs the command trough a filter to check whether any of the words
  # it uses are disallowed.
  # @param [String] params The parameters to check for censored words.
  def check_filters params
    return false if @@filter.empty? or params.start_with?("unfilter")
    return Regexp.new("(#{@@filter.join("|")})").match(params)
  end

  # Checks whether the user actually has access to the command and can use it.
  # @param [Event] event The event that was recieved.
  # @param [Symbol] privilege The privilege level required for the command.
  def check_access event, privilege
    nick = Scarlet::Nick.first(:nick => event.sender.nick)
    ban = Scarlet::Ban.first(:nick => nick.nick) if nick
    if ban and ban.level > 0 and ban.servers.include?(event.server.config.address)
      event.reply "#{event.sender.nick} is banned and cannot use any commands."
      return false
    end
    return true if privilege == :any # if it doesn't need clearance (:any)
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

  # A callback instance, which contains a callback command that we can save for
  # later and run it at a later time, when the event listener tied to it matches.
  class Callback
    # Create a new callback instance,
    # @param [Proc] block The block we want to call as a callback.
    def initialize block
      @block = block
    end

    # Run our stored callback, passing in the event we captured and the matches
    # from our command.
    # @param [Event] event The event we captured.
    # @param [MatchData] matches The matches we caught when we matched the
    #  callback to the event.
    def run event, matches
      @event = event
      @event.params = matches
      self.instance_eval &@block
    end

    delegate :msg, :notice, :reply, :action, :send, :send_cmd, to: :@event

    # DSL delegator, delegates calls to +@event+ to be able to directly use it's
    # attributes. 
    def method_missing method, *args
      return @event.__send__ method, *args if @event.respond_to? method
      super
    end

    # Get a context of the nick, you = the bot, me = the sender.
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