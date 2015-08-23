require 'scarlet/plugin'

module Scarlet::Plugins
  class Command
    include Scarlet::Plugin

    on :privmsg do |event|
      # if we detect a command sequence, we remove the prefix and execute it.
      # it is prefixed with config.control_char or by mentioning the bot's current nickname
      if event.params.first =~ /^#{event.server.current_nick}[:,]?\s*/i
        event.params[0] = event.params[0].split[1..-1].join(' ')
        process_command(event.dup)
      elsif event.params.first.starts_with? config.control_char
        event.params.first.slice!(0)
        process_command(event.dup)
      end
    end

    def initialize
      # Contains all of our listeners.
      # @return [Hash<Regexp, Listener>]
      @listeners = {}
      # Any words we want to filter.
      @filter = []

      @loader = Scarlet::Command::Loader.new(self)
      load_commands
    end

    # Loads a command file from the given path
    #
    # @param [String] path
    def load_command(path)
      puts "Loading command: #{path}"
      @loader.load_file path
    end

    # Loads a command file from the given name.
    def load_command_rel(name)
      load_command File.join(Scarlet.root, 'commands', name)
    end

    # Loads (or reloads) commands from the /commands directory under the
    # +Scarlet.root+ path.
    def load_commands
      old_listeners = @listeners.dup
      @listeners.clear
      begin
        commands = []
        Dir[File.join(Scarlet.root, 'commands/**/*.rb')].each do |path|
          commands << load_command(path)
        end
        commands.each do |command|
          @listeners.merge!(command.listeners)
        end
        true
      rescue => ex
        puts ex.inspect
        puts ex.backtrace.join("\n")
        @listeners.replace old_listeners
        false
      end
    end

    # Selects all commands which evaluate true in the block.
    #
    # @yieldparam [Listener]
    # @return [Array<Listener>]
    def select_commands
      return to_enum :select_commands unless block_given?
      @listeners.each_value.select do |l|
        yield l
      end
    end

    # Selects all commands which match the provided command string
    #
    # @param [String] command
    # @return [Array<Listener>]
    def match_commands command
      select_commands { |c| c.usage.include? command }
    end

    # Returns help matching the specified string. If no command is used, then
    # returns the entire list of help.
    #
    # @param [String] command The keywords to search for.
    def get_help command = nil
      help = if c = command.presence
               match_commands(c).map(&:help)
             else
               @listeners.each_value.map(&:help)
             end
      # map each by #presence (exposing empty strings),
      # remove all nil entries from presence,
      # make each line unique,
      # and finally sort the result.
      help.map(&:presence).compact.uniq.sort
    end

    # Initialize is here abused to run a new instance of the Command.
    #
    # @param [Event] event The event that was caught by the server.
    def process_command event
      if word = check_filters(event.params.first)
        event.reply "Cannot execute because \"#{word}\" is blocked."
        return
      end

      @listeners.keys.each do |key|
        listener = @listeners[key]
        key.match event.params.first do |matches|
          if check_access(event, listener.clearance)
            ev = event.dup.tap { |ev| ev.data[:commands] = self }
            listener.invoke ev, matches
          end
        end
      end
    end

    private # Make the checks private.

    # Runs the command trough a filter to check whether any of the words
    # it uses are disallowed.
    # @param [String] params The parameters to check for censored words.
    def check_filters params
      return false if @filter.empty? or params.start_with?("unfilter")
      return Regexp.new("(#{@filter.join("|")})").match params
    end

    # Checks whether the user actually has access to the command and can use it.
    # @param [Event] event The event that was recieved.
    # @param [Proc] clearance  proc to determine if the use passes clearance
    # @return [Boolean] True if access is allowed, else false.
    def check_access event, clearance
      nick = Scarlet::Nick.first nick: event.sender.nick
      return false if check_ban(event) # if the user is banned
      return true unless clearance

      if event.server.users.get(event.sender.nick).ns_login # check login
        if !nick # check that user is registered
          event.reply "Registration not found, please register."
          return false
        elsif !clearance.call(nick)
          event.reply "Your security clearance does not grant access."
          return false
        end
      else
        event.reply "Test subject #{event.sender.nick} is not logged in with NickServ."
        return false
      end
      return true
    end

    # @return [Boolean] true if user is banned, else false.
    def check_ban event
      ban = Scarlet::Ban.first nick: event.sender.nick
      if ban and ban.level > 0 and ban.servers.include?(event.server.config.address)
        event.reply "#{event.sender.nick} is banned and cannot use any commands."
        return true
      end
      return false
    end
  end
end
