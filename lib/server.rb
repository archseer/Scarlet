load "modules/scarlet/lib/output_helper.rb"
module Scarlet
class Server
  include ::OutputHelper
  attr_accessor :scheduler, :log, :reconnect, :banned
  attr_accessor :connection, :current_nick, :config, :ircd
  attr_reader :channels

  def initialize(config) # irc could/should have own handlers.
    @config = config
    @current_nick = config.nick #|| @current_nick

    @path = File.dirname(__FILE__)
    @log = Log.new
    @log.start_log :connection

    @scheduler = Scheduler.new
    @irc_commands = YAML.load_file("#{@path}/../commands.yml").symbolize_keys!
    @channels = {}    # holds data about the users on channel
    @banned = []      # who's banned here?
    @modes = []       # bot account's modes (ix,..)
    @extensions = {}  # what the server-side supports
    @reconnect = true
    
    # // All known modes
    @base_mode_list = {
      :owner      => {:name=>'owner'     ,:prefix=>'q',:symbol=>'~'},
      :admin      => {:name=>'admin'     ,:prefix=>'a',:symbol=>'&'},
      :op         => {:name=>'operator'  ,:prefix=>'o',:symbol=>'@'},
      :hop        => {:name=>'halfop'    ,:prefix=>'h',:symbol=>'%'},
      :voice      => {:name=>'voice'     ,:prefix=>'v',:symbol=>'+'},
      :registered => {:name=>'registered',:prefix=>'r',:symbol=>'' }
    }
  end
  # // Only return supported modes
  def mode_list
    hsh = @base_mode_list.dup
    prefix2key = hsh.remap{|k,v|[v[:symbol],k]}
    supmodes = @extensions[:prefix].match(/\(([qaohv]*)\)([~&@%+]*)/)[1,2]
    #supmodes[0] # // :prefix(s)
    #supmodes[1] # // :symbol(s)
    supped = prefix2key.keys&supmodes[0].split("")
    Hash[supped.collect { |prfx| [prefix2key[prfx], hsh[prefix2key[prfx]]] }]
  end
  def disconnect
    send_cmd :quit, :quit => $config.irc_bot.quit
    @reconnect = false
    connection.close_connection(true)
  end

  def unbind
    @channels = {}
    @modes = []
    @extensions = {}
    
    reconnect = lambda {
      puts "Connection to server lost. Reconnecting...".light_red
      connection.reconnect(@config.address, @config.port) rescue return EM.add_timer(3) { reconnect.call }
      connection.post_init
    }
    EM.add_timer(3) { reconnect.call } if @reconnect
  end

  def send_data data
    connection.send_data data
  end

  def receive_line line
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

    print_chat event.sender.nick, event.params.first, false, event.channel
    # simple channel symlink. added: now it doesn't relay any bot commands (!)
    if event.channel && event.sender.nick != @current_nick && $config.irc_bot.relay && event.params.first[0] != $config.irc_bot.control_char
      @channels.keys.reject{|key| key == event.channel}.each {|chan| 
        msg "#{chan}", "[#{event.channel}] <#{event.sender.nick}> #{event.params.first}", true
      }
    end
    Command.new(self, event.dup) if (event.params.first.split(' ')[0] =~ /^#{@current_nick}[:,]?\s*/i) || event.params[0].start_with?("!")
  when :notice # Automatic replies must never be sent in response to a NOTICE message.
    if event.sender.nick == "NickServ" 
      if ns_params = event.params.first.match(/STATUS\s(?<nick>\S+)\s(?<digit>\d)$/i) || ns_params = event.params.first.match(/(?<nick>\S+)\sACC\s(?<digit>\d)$/i)
      if ns_params[:digit] == "3" && !User.ns_login?(@channels, ns_params[:nick])
        User.ns_login @channels, ns_params[:nick]
        nik = Nick.where(:nick => ns_params[:nick]).first
        notice ns_params[:nick], "#{ns_params[:nick]}, you are now logged in with #{@current_nick}." if nik && nik.settings[:notify_login] && !$config.irc_bot.testing
      end
      end
    else
      print_console "-#{event.sender.nick}-: #{event.params.first}", :light_cyan if event.sender.nick != "Global" # hack
    end
  when :join
    if @current_nick != event.sender.nick
      print_console "#{event.sender.nick} (#{event.sender.username}@#{event.sender.host}) has joined channel #{event.channel}.", :light_yellow, event.channel
      check_nick_login event.sender.nick
    else
      @log.start_log event.channel
      @channels[event.channel] = {:users => {}, :flags => []}
      send_data "MODE #{event.channel}"
      print_console "Joined channel #{event.channel}.", :light_yellow, event.channel
    end
    @channels[event.channel][:users][event.sender.nick] = {}
  when :part
    if event.sender.nick == @current_nick
      print_console "Left channel #{event.channel} (#{event.params.first}).", :light_magenta, event.channel
      @channels.delete event.channel # remove chan if bot parted
      @log.close_log event.channel
    else
      print_console "#{event.sender.nick} has left channel #{event.channel} (#{event.params.first}).", :light_magenta, event.channel
      @channels[event.channel][:users].delete event.sender.nick
    end
  when :quit
    print_console "#{event.sender.nick} has quit (#{event.target}).", :light_magenta
    @channels.keys.each {|key| @channels[key][:users].delete event.sender.nick}
  when :nick
    @channels.keys.each {|key| @channels[key][:users].rename_key!(event.sender.nick, event.target)}
    if event.sender.nick == @current_nick
      @current_nick = event.target
      print_console "You are now known as #{event.target}.", :light_yellow
    else
      print_console "#{event.sender.nick} is now known as #{event.target}.", :light_yellow
    end
  when :kick
    messg = "#{event.sender.nick} has kicked #{event.params.first} from #{event.target}"
    messg += " (#{event.params[1]})" if event.params[1] != event.sender.nick
    messg += "."
    print_console messg, :light_red, event.target
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
        flags = mode_list.remap { |k,v| [v[:prefix],v[:name].to_sym] }
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
  when :topic # Channel topic was changed
    print_console "#{event.sender.nick} changed #{event.channel} topic to #{event.params.first}", :light_green
  when :error # Either the server acknowledged disconnect, or there was a serious issue with something
    if event.target.start_with? "Closing Link"
      puts "Disconnection from #{@config.address} successful.".blue
    else
      puts "ERROR: #{event.params.join(" ")}".red
    end
  when :"001"
    msg "NickServ", "IDENTIFY #{@config.password}", true if @config.password
  when :"004"
    @ircd = event.params[1]
  when :"005"
    event.params.each { |segment|
      if s = segment.match(/(?<token>.+)\=(?<parameters>.+)/)
        param = s[:parameters].match(/^[[:digit:]]+$/) ? s[:parameters].to_i : s[:parameters] # convert digit only to digits
        @extensions[s[:token].downcase.to_sym] = param
      else
        @extensions[segment.downcase.to_sym] = true
      end
    }
  when /00\d/ # Login procedure
    print_console event.params.first, :light_green if $config.irc_bot.display_logon
  when :'324' # Chan mode
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
    @current_nick += "Bot"
    send_cmd :nick, :nick => @current_nick
  when :'353' # NAMES list
    # param[0] --> chantype: "@" is used for secret channels, "*" for private channels, and "=" for others (public channels).
    # param[1] -> chan, param[2] - users
    event.params[2].split(" ").each { |nick| nick, @channels[event.params[1]][:users][nick] = Parser.parse_names_list self, nick }
  when :'366' # end of /NAMES list
    @channels[event.params.first][:users].keys.each { |nick| check_nick_login nick} # check permissions of users
  when :'375' # START of MOTD
    # this is immediately after 005 messages usually so set up extended NAMES command
    send_data "PROTOCTL NAMESX" if @extensions[:namesx]
  when :'376' # END of MOTD command. Join channel(s)!
    send_cmd :join, :channel => @config.channel
  when /(372|26[56]|25[1245])/ #Ignore MOTD and some statuses
  when /4\d\d/ # Error messages range
    print_console event.params.join(" "), :light_red
    msg @config.channel, "ERROR: #{event.params.join(" ")}".irc_color(4,0), true #TODO: Output only certain messages to channel.
  else
    print_console "TODO SERV -- sender: #{event.sender.inspect}; command: #{event.command.inspect}; 
    target: #{event.target.inspect}; channel: #{event.channel.inspect}; params: #{event.params.inspect};", :yellow
  end
 end
  #----------------------------------------------------------
  def send_cmd cmd, hash
    send_data Mustache.render(@irc_commands[cmd], hash)
  end

  def msg target, message, silent=false
    send_data "PRIVMSG #{target} :#{message}"
    log_name = target[0] == '#' ? target : :connection
    print_chat @current_nick, message, silent, log_name unless silent
  end

  def notice target, message, silent=false
    send_data "NOTICE #{target} :#{message}"
    log_name = target[0] == '#' ? target : :connection
    print_console ">#{target}< #{message}", :light_cyan, log_name unless silent
  end

  def check_nick_login nick
    msg "NickServ", "ACC #{nick}", true if @ircd =~ /ircd-seven/i # freenode
    msg "NickServ", "STATUS #{nick}", true if @ircd =~ /unreal/i
  end
end
end