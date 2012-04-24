load "modules/irc_bot/lib/output_helper.rb"
class IrcBot::Bot < EM::Connection
  include EventMachine::Protocols::LineText2
  include ::OutputHelper
  attr_accessor :scheduler, :log, :disconnecting, :banned
  attr_reader :channels

  def post_init
    path = File.dirname(__FILE__)
    @log = Logger.new("#{path}/../logs/irc.log", 'daily')
    @log.info "\n**** NEW SESSION at #{Time.now}"

    @scheduler = Scheduler.new
    @user_commands = YAML.load_file("#{path}/../commands.yml").symbolize_keys!
    @channels = {}
    @banned = []
    @modes = []
    @disconnecting = false
    connect
    reset_check_connection_timer
  rescue => e
    p e
  end

  def connect
    send_cmd :nick, :nick => $config.irc_bot.nick
    send_cmd :user, :host => $config.irc_bot.host, :nick => $config.irc_bot.nick, :name => $config.irc_bot.name
  end

  def unbind
    @check_connection_timer.cancel if @check_connection_timer
    puts "DEBUG: Socket has unbound.".red
    if !@disconnecting
      print_console "Connection to server lost.", :light_red
      Modules.restart_mod :IrcBot
    end
  end

  def send_data data
    super "#{data}\r"
  end

  def receive_line line
    reset_check_connection_timer
    return if @disconnecting
    parsed_line = IRC::Parser.parse line
    event = IRC::Event.new(:localhost, parsed_line[:prefix],
                      parsed_line[:command].downcase.to_sym,
                      parsed_line[:target], parsed_line[:params])
    handle_event event
  end
 #---handle_event--------------------------------------------
 def handle_event(event)
  case event.command
  when :ping
    puts("[ Server ping ]") if $config.irc_bot.display_ping
    send_data "PONG :#{event.target}"
  when :pong
    puts "[ Ping reply from #{event.sender.host} ]"
  when :privmsg
    if event.params.first =~ /\001PING (.+)\001/
      puts "[ CTCP PING from #{event.sender.nick} ]" and send_data "NOTICE #{event.sender.nick} :\001PING #{$1}\001"
      return
    elsif event.params.first =~ /\001VERSION\001/
      puts "[ CTCP VERSION from #{event.sender.nick} ]" and send_data "NOTICE #{event.sender.nick} :\001VERSION RubyxCube v0.8\001"
      return
    end

    print_chat event.sender.nick, event.params.first
    privmsg_reactor event if event.params.first[0] == $config.irc_bot.control_char
    # simple channel symlink
    # added: now it doesn't relay any bot commands (!)
    if event.channel && event.sender.nick != $config.irc_bot.nick && $config.irc_bot.relay && event.params.first[0] != $config.irc_bot.control_char
      @channels.keys.reject{|key| key == event.channel}.each {|chan| 
        msg "#{chan}", "[#{event.channel}] <#{event.sender.nick}> #{event.params.first}", true
      }
    end
    Scarlet.new(self, event.dup) if event.params.first.split(' ')[0] =~ /#{$config.irc_bot.nick}[:,]?\s*/i
  when :notice # Automatic replies must never be sent in response to a NOTICE message.
    if event.sender.nick == "NickServ" && ns_params = event.params.first.match(/(?:ACC|STATUS)\s(?<nick>\S+)\s(?<digit>\d)$/i)
      if ns_params[:digit] == "3" && !::IrcBot::User.ns_login?(@channels, ns_params[:nick])
        ::IrcBot::User.ns_login @channels, ns_params[:nick]
        notice ns_params[:nick], "#{ns_params[:nick]}, you are now logged in with #{$config.irc_bot.nick}." if !::IrcBot::Nick.where(:nick => ns_params[:nick]).empty?
      end
    else
      print_console "-#{event.sender.nick}-: #{event.params.first}", :light_cyan if event.sender.nick != "Global" # hack
    end
  when :join
    if $config.irc_bot.nick != event.sender.nick
      print_console "#{event.sender.nick} (#{event.sender.username}@#{event.sender.host}) has joined channel #{event.channel}.", :light_yellow
      check_nick_login event.sender.nick
    else
      @channels[event.channel] = {:users => {}, :flags => []}
      send_data "MODE #{event.channel}"
      print_console "Joined channel #{event.channel}.", :light_yellow
    end
    @channels[event.channel][:users][event.sender.nick] = {}
  when :part
    if event.sender.nick == $config.irc_bot.nick
      print_console "Left channel #{event.channel} (#{event.params.first}).", :light_magenta
      @channels.delete event.channel # remove chan if bot parted
    else
      print_console "#{event.sender.nick} has left channel #{event.channel} (#{event.params.first}).", :light_magenta
      @channels[event.channel][:users].delete event.sender.nick
    end
  when :quit
    print_console "#{event.sender.nick} has quit (#{event.target}).", :light_magenta
    @channels.keys.each {|key| @channels[key][:users].delete event.sender.nick}
  when :nick
    @channels.keys.each {|key| @channels[key][:users].rename_key!(event.sender.nick, event.target)}
    if event.sender.nick == $config.irc_bot.nick
      $config.irc_bot[:nick] = event.target
      print_console "You are now known as #{event.target}.", :light_yellow
    else
      print_console "#{event.sender.nick} is now known as #{event.target}.", :light_yellow
    end
  when :kick
    messg = "#{event.sender.nick} has kicked #{event.params.first} from #{event.target}"
    messg += " (#{event.params[1]})" if event.params[1] != event.sender.nick
    messg += "."
    print_console messg, :light_red
  when :mode
    if event.sender.server? # Parse bot's private modes (ix,..) -- SERVER
      mode = true
      event.params.first.split("").each do |c|
        mode = (c=="+") ? true : (c == "-" ? false : mode)
        next if c == "+" or c == "-" or c == " "
        mode ? @modes << c : @modes.subtract_once(c)
      end
    else # USER modes
      mode = true
      event.params.compact!
      if event.params.count > 1 # means we have an user list
        flags = {"q" => :owner, "a" => :admin, "o" => :operator, "h" => :halfop, "v" => :voice, "r" => :registered}
        operator_count = 0
        nicks = event.params[1..-1]

        event.params.first.split("").each_with_index do |flag, i|
          mode = (flag=="+") ? true : (flag == "-" ? false : mode)
          operator_count += 1 and next if flag == "+" or flag == "-" 
          next if flag == " "
          nick = nicks[i-operator_count]
          if nick[0] != "#" 
            @channels[event.channel][:users][nick][flags[flag]] = mode 
          else
            mode ? @channels[event.channel][:flags] << c : @channels[event.channel][:flags].subtract_once(c)
          end
        end
      else # means we apply the flags to the channel.
        event.params.first.split("").each do |c|
          mode = (c=="+") ? true : (c == "-" ? false : mode)
          next if c == "+" or c == "-" or c == " "
          mode ? @channels[event.channel][:flags] << c : @channels[event.channel][:flags].subtract_once(c)
        end
      end
    end
  when :"001"
    msg "NickServ", "IDENTIFY #{$config.irc_bot.password}", true if $config.irc_bot[:password]
  when :"005"
    event.params.each { |segment|
      if s = segment.match(/(?<token>.+)\=(?<parameters>.+)/)
        param = s[:parameters].match(/^[[:digit:]]+$/) ? s[:parameters].to_i : s[:parameters] # convert digit only to digits
        $config.irc_bot.extensions[s[:token].downcase.to_sym] = param
      else
        $config.irc_bot.extensions[segment.downcase.to_sym] = true
      end
    }
  when /00\d/
    print_console event.params, :light_green if $config.irc_bot.display_logon
  when :'324' # chan mode
    mode = true
    event.params[1].split("").each do |c|
      mode = (c=="+") ? true : (c == "-" ? false : mode)
      next if c == "+" or c == "-" or c == " "
      mode ? @channels[event.params.first][:flags] << c : modes.subtract_once(c)
    end
  when :'329' # Channel created at
    print_console "#{event.params[0]} created at #{Time.at(event.params[1].to_i).std_format}", :light_green
  when :'332' # Channel topic
    message = "Topic for #{event.params.first} is: #{event.params[1]}"
    print_console message, :light_green
  when :'333' # Channel topic set by
    print_console "Topic for #{event.params[0]} set by #{event.params[1]} at #{Time.at(event.params[2].to_i).std_format}", :light_green
  when :'433' # Nickname exists
    $config.irc_bot.nick += "Bot"
    send_cmd :nick, :nick => $config.irc_bot.nick
  when :'353' # NAMES list
    # param[0] --> chantype: "@" is used for secret channels, "*" for private channels, and "=" for others (public channels).
    # param[1] -> chan, param[2] - users
    event.params[2].split(" ").each { |nick| nick, @channels[event.params[1]][:users][nick] = ::IrcBot::Parser.parse_names_list nick }
  when :'366' # end of /NAMES list
    @channels[event.params.first][:users].keys.each { |nick| check_nick_login nick} # check permissions of users
  when :'375' # START of MOTD
    # this is immediately after 005 messages usually so set up extended NAMES command
    send_data "PROTOCTL NAMESX" if $config.irc_bot.extensions[:namesx]
  when :'376' # END of MOTD command. Join channel(s)!
    send_cmd :join, :channel => $config.irc_bot.channel
  when /(372|26[56]|25[1245])/ #Ignore MOTD and some statuses
  when /4\d\d/ # Error messages range
    print_console event.params.join(" "), :light_red
    msg $config.irc_bot.channel, "ERROR: #{event.params.join(" ")}".irc_color(4,0), true #TODO: Output only certain messages to channel.
  else
    print_console "TODO SERV -- sender: #{event.sender.inspect}; command: #{event.command.inspect}; 
    target: #{event.target.inspect}; channel: #{event.channel.inspect}; params: #{event.params.inspect};", :yellow
  end
 end
 #----privmsg reactor -------------------------------------
  def privmsg_reactor event
    command  = event.params.first.split[0...1].join(' ')
    sequence = event.params.first.split(' ').drop(1).join(' ')
    cmd = ::IrcBot::Commands[command[1..-1].to_sym]
    if cmd && !cmd[:disable] && !@banned.include?(event.sender.nick) # command exists, not disabled and user not banned
      if cmd[:access_level].nil_zero? # no access level, just execute the function
        self.instance_exec sequence, event, &cmd[:method] # execute it
      else # it requires permissions
        nick = ::IrcBot::Nick.where(:nick => event.sender.nick)
        if !::IrcBot::User.ns_login? @channels, event.sender.nick # user was not logged in
          notice event.sender.nick, "#{event.sender.nick}, you are not logged in!"
        elsif nick.count > 0 && nick.first.privileges >= cmd[:access_level] # nick exists and privileges grant access
          self.instance_exec sequence, event, &cmd[:method]
        end
      end
    end
  rescue(Exception) => result
    msg $config.irc_bot.channel, "ERROR: #{result.message}".irc_color(4,0)
  end
  #----------------------------------------------------------
  def send_cmd cmd, hash
    send_data Mustache.render(@user_commands[cmd], hash)
  end

  def msg target, message, silent=false
    send_data "PRIVMSG #{target} :#{message}"
    print_chat $config.irc_bot.nick, message, silent
  end

  def notice target, message, silent=false
    send_data "NOTICE #{target} :#{message}"
    print_console ">#{target}< #{message}", :light_cyan unless silent
  end

  def check_nick_login nick
    msg "NickServ", "STATUS #{nick}", true
  end

  private
  def check_connection
    puts "Sending PING to server to verify connection..."
    send_cmd :ping, :target => $config.irc_bot.server
    @check_connection_timer = EM::Timer.new(30, method(:timeout))
  end

  def timeout
    puts "Timed out waiting for server, reconnecting..."
    send_cmd :quit, :quit => "Ping timeout"
    close_connection_after_writing
  end

  def reset_check_connection_timer
    @check_connection_timer.cancel if @check_connection_timer
    @check_connection_timer = EM::Timer.new(100, method(:check_connection))
  end
end