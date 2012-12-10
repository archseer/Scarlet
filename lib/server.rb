module Scarlet

  # This class is the meat of the bot, encapsulating the connection and
  # various event listeners that respond to server messages, as well as 
  # a list of users and channels the bot is connected to. All the magic 
  # happens in this class.
  class Server
    include ActiveSupport::Configurable
    attr_accessor :scheduler, :banned, :connection
    attr_reader :channels, :users, :state, :extensions, :cap_extensions, :current_nick, :vHost

    # Initializes a new abstracted connection instance to an IRC server. 
    # The actual EM connection instance gets set to +self.connection+.
    def initialize cfg
      config.merge! cfg.symbolize_keys
      @current_nick = config.nick
      config.control_char ||= Scarlet.config.control_char
      config.freeze

      @scheduler = Scheduler.new
      @channels  = ServerChannels.new # channels
      @users     = Users.new          # users (seen) on the server
      @state     = :connecting
      reset_vars
    end  

    # Resets the variables to their default values. This gets triggered when the
    # instance gets created as well as any time the bot reconnects to the server.
    def reset_vars
      @banned         = []     # who's banned here?
      @modes          = []     # bot account's modes (ix,..)
      @extensions     = {}     # what the server-side supports (PROTOCTL)
      @cap_extensions = {}     # CAPability extensions (CAP REQ)
      @vHost          = nil    # vHost/cloak
    end

    # An alias for config.server_name.
    def name
      config.server_name
    end

    # Disconnects the bot from the network. It sends a +QUIT+ message to the server,
    # and closes the connection to the server.
    def disconnect
      send "QUIT :#{Scarlet.config.quit}"
      @state = :disconnecting
      connection.close_connection(true)
    end

    # This method gets called from the connection instance once the connection to
    # the server was closed. It checks whether we actually wanted to disconnect, or
    # whether the bot lost connection from the server. If the connection was 
    # unintentional, it starts the reconnection process.
    def unbind
      @channels.clear
      @users.clear
      reset_vars

      reconnect = lambda {
        print_error "Connection to server lost. Reconnecting..."
        connection.reconnect(@config.address, @config.port) rescue return EM.add_timer(3) { reconnect.call }
        connection.post_init
        init_vars
      }
      EM.add_timer(3) { reconnect.call } if not @state == :disconnecting
    end

    def send data
      if data =~ /(PRIVMSG|NOTICE)\s(\S+)\s(.+)/i
        stack = []
        command, trg, text = $1, $2, $3
        length = 510 - command.length - trg.length - 2 - 120
        text.word_wrap(length).split("\n").each do |s| stack << '%s %s %s' % [command,trg,s] end
      else
        stack = [data]
      end
      stack.each {|d| connection.send_data d}
      nil
    end

    # Parses the recieved line from the server and creates a new event out of it,
    # then it logs the event and distributes the event over to handlers.
    def receive_line line
      parsed_line = Parser.parse_line line
      event = Event.new(self, parsed_line[:prefix],
                        parsed_line[:command].downcase.to_sym,
                        parsed_line[:target], parsed_line[:params])
      Log.write(event)
      handle_event event
    end

    # Sends a PRIVMG message to +target+. Logs the message to the log.
    def msg target, message
      send "PRIVMSG #{target} :#{message}"
      write_log :privmsg, message, target
    end

    # Sends a NOTICE message to +target+. Logs the message to the log.
    def notice target, message
      send "NOTICE #{target} :#{message}"
      write_log :notice, message, target
    end

    # Joins all the channels listed as arguments.
    #
    #  join '#channel', '#bots'
    #
    # One can also pass in a password for the channel by separating the password 
    # and channel name with a space.
    #
    #  join '#channel password'
    #
    def join *channels
      send "JOIN #{channels.join(',')}"
    end

    # Write down the command to the log (in our case a MongoDB database), ignoring
    # any message sent to +*Serv+ bots.
    def write_log command, message, target
      return if target =~ /Serv$/ # if we PM a bot, i.e. for logging in, that shouldn't be logged.
      log = Log.new(:nick => @current_nick, :message => message, :command => command.upcase, :target => target)
      log.channel = target if target.starts_with? "#"
      log.save!
    end

    # Prints a message to the console with a timestamp. Optionally color of the
    # message can be passed in as a symbol. If debug is set to false in the config,
    # no messages will be logged.
    def print_console message, color=nil
      return unless Scarlet.config.debug
      msg = Scarlet::Parser.parse_esc_codes message
      msg = "[#{Time.now.strftime("%H:%M")}] #{msg}"
      puts color ? msg.colorize(color) : msg
    end

    # Prints a message in the same format as +print_console+. Message will be
    # output to console, regardless of the debug value in the config.
    def print_error message
      msg = Scarlet::Parser.parse_esc_codes message
      msg = "[#{Time.now.strftime("%H:%M")}] #{msg}"
      puts msg.colorize(:light_red)
    end

    def check_ns_login nick
      # According to the docs, those servers that use STATUS may query up to
      # 16 nicknames at once. if we pass an Array do:
      #   a) on STATUS send groups of up to 16 nicknames
      #   b) on ACC, we have no such luck, send each message separately.

      if nick.is_a? Array
        if @ircd =~ /unreal/i
          nick.each_slice(16) {|group| msg "NickServ", "STATUS #{group.join(' ')}"}
        else
          nick.each {|nickname| msg "NickServ", "ACC #{nick}"}
        end 
      else # one nick was given, send the message
        msg "NickServ", "ACC #{nick}" if @ircd =~ /ircd-seven/i # freenode
        msg "NickServ", "STATUS #{nick}" if @ircd =~ /unreal/i
      end
    end

  end
end