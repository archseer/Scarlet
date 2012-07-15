load "modules/scarlet/lib/output_helper.rb"
module Scarlet
  # // All known modes
  @base_mode_list = {
    :owner      => {:name=>'owner'     ,:prefix=>'q',:symbol=>'~'},
    :admin      => {:name=>'admin'     ,:prefix=>'a',:symbol=>'&'},
    :op         => {:name=>'operator'  ,:prefix=>'o',:symbol=>'@'},
    :hop        => {:name=>'halfop'    ,:prefix=>'h',:symbol=>'%'},
    :voice      => {:name=>'voice'     ,:prefix=>'v',:symbol=>'+'},
    :registered => {:name=>'registered',:prefix=>'r',:symbol=>'' }
  }
  def self.base_mode_list; @base_mode_list; end
class Server
  include ::OutputHelper
  attr_accessor :scheduler, :reconnect, :banned
  attr_accessor :connection, :config
  attr_reader :channels, :extensions, :cap_extensions, :handshake, :current_nick, :ircd
  attr_reader :base_mode_list, :mode_list, :vHost
  def initialize config  # irc could/should have own handlers.
    @config = config
    @current_nick = config.nick
    @config[:control_char] ||= Scarlet.config.control_char
    @scheduler = Scheduler.new
    @irc_commands = YAML.load_file("#{Scarlet.root}/commands.yml").symbolize_keys!
    @channels = {}    # holds data about the users on channel
    @banned = []      # who's banned here?
    @modes = []       # bot account's modes (ix,..)
    @extensions = {}  # what the server-side supports (PROTOCTL)
    @cap_extensions = {} # CAPability extensions (CAP REQ)
    @handshake        # set to true after we connect (001)
    @reconnect = true
    @vHost = nil

    @mode_list = {} # Temp
  end

  def disconnect
    send_cmd :quit, :quit => Scarlet.config.quit
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
    if data =~ /(PRIVMSG|NOTICE)\s(\S+)\s(.+)/i
      stack = []
      command, trg, text = $1, $2, $3
      length = 510 - command.length - trg.length - 2 # // 2 whitespace
      text.character_wrap(length).each do |s| stack << '%s %s %s' % [command,trg,s] end
    else
      stack = [data]
    end
    stack.each do |d| connection.send_data d end
    nil
  end

  def receive_line line
    parsed_line = IRC::Parser.parse line
    event = IRC::Event.new(:localhost, parsed_line[:prefix],
                      parsed_line[:command].downcase.to_sym,
                      parsed_line[:target], parsed_line[:params])
    Log.write(event)
    handle_event event
  end
 #---handle_event--------------------------------------------
 def handle_event event
  case event.command
  when :ping
    puts("[ Server ping ]") if Scarlet.config.display_ping
    send_data "PONG :#{event.target}"
  when :pong
    puts "[ Ping reply from #{event.sender.host} ]"
  when :privmsg
    if event.params.first =~ /\001PING (.+)\001/
      puts "[ CTCP PING from #{event.sender.nick} ]" and send_data "NOTICE #{event.sender.nick} :\001PING #{$1}\001"
      return
    elsif event.params.first =~ /\001VERSION\001/
      puts "[ CTCP VERSION from #{event.sender.nick} ]" and send_data "NOTICE #{event.sender.nick} :\001VERSION RubyxCube v1.0\001"
      return
    end

    print_chat event.sender.nick, event.params.first, false
    # simple channel symlink. added: now it doesn't relay any bot commands (!)
    if event.channel && event.sender.nick != @current_nick && Scarlet.config.relay && event.params.first[0] != @config.control_char
      @channels.keys.reject{|key| key == event.channel}.each {|chan|
        msg "#{chan}", "[#{event.channel}] <#{event.sender.nick}> #{event.params.first}", true
      }
    end
    # check for http:// URL's and output their titles (TO IMPROVE! THESE INDENTS ARE ANNOYING!)
    event.params.first.match(/(http:\/\/[^ ]*)/) {|url|
      begin
        EM::HttpRequest.new(url).get(:redirects => 1).callback {|http|
          http.response.match(/<title>(.*)<\/title>/) {|title| 
            msg event.return_path, "Title: #{title[1]}" #(domain)
          }
        }
      rescue(Exception)
      end
    }

    Command.new(self, event.dup) if (event.params.first.split(' ')[0] =~ /^#{@current_nick}[:,]?\s*/i) || event.params[0].starts_with?(@config.control_char)
  when :notice
    # handle NickServ login checks
    if event.sender.nick == "NickServ"
      if ns_params = event.params.first.match(/STATUS\s(?<nick>\S+)\s(?<digit>\d)$/i) || ns_params = event.params.first.match(/(?<nick>\S+)\sACC\s(?<digit>\d)$/i)
        User.ns_login @channels, ns_params[:nick] if ns_params[:digit] == "3" && !User.ns_login?(@channels, ns_params[:nick])
      end
    elsif event.sender.nick == "HostServ"
      event.params.first.match(/Your vhost of \x02(\S+)\x02 is now activated./i) {|host| 
        @vHost = host[1]
        print_console "#{@vHost} is now your hidden host (set by services.)", :light_magenta
      }
    else # not from NickServ or HostServ -- normal notice
      print_console "-#{event.sender.nick}-: #{event.params.first}", :light_cyan if event.sender.nick != "Global" # hack, ignore notices from Global (wallops?)
    end
  when :join
    # :nick!user@host JOIN :#channelname - normal
    # :nick!user@host JOIN #channelname accountname :Real Name - extended-join

    if @current_nick != event.sender.nick
      print_console "#{event.sender.nick} (#{event.sender.username}@#{event.sender.host}) has joined channel #{event.channel}.", :light_yellow
      if !event.params.empty? && @cap_extensions["extended-join"]
        # extended-join is enabled, which means that join returns two extra params, 
        # NickServ account name and real name. This means, we don't need to query 
        # NickServ about the user's login status.
        @channels[event.channel][:users][event.sender.nick] ||= {}
        @channels[event.channel][:users][event.sender.nick][:ns_login] = true
        @channels[event.channel][:users][event.sender.nick][:account_name] = event.params[0]
      else
        # No luck, we need to manually query for a login check.
        # a) if WHOX is available, query with WHOX.
        # b) if still no luck, query NickServ.
        if @cap_extensions[:whox]
          send_data "WHO #{event.params.first} %nact,42" # we use the 42 to locally identify login checks
        else
          check_ns_login event.sender.nick
        end
      end
    else
      @channels[event.channel] = {users: {}, flags: []}
      send_cmd :mode, :mode => event.channel
      print_console "Joined channel #{event.channel}.", :light_yellow
    end
    @channels[event.channel][:users][event.sender.nick] ||= {}
  when :part
    if event.sender.nick == @current_nick
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
    @channels.keys.each do |key| @channels[key][:users].replace_key! event.sender.nick => event.target end
    if event.sender.nick == @current_nick
      @current_nick = event.target
      print_console "You are now known as #{event.target}.", :light_yellow
    else
      print_console "#{event.sender.nick} is now known as #{event.target}.", :light_yellow
    end
  when :kick
    messg  = "#{event.sender.nick} has kicked #{event.params.first} from #{event.target}"
    messg += " (#{event.params[1]})" if event.params[1] != event.sender.nick # reason for kick, if given
    messg += "."
    print_console messg, :light_red, event.target
    # we process this the same way as a part.
    if event.params.first == @current_nick
      @channels.delete event.channel # if scarlet was kicked, delete that chan's array.
    else
      @channels[event.target][:users].delete event.params.first # remove the kicked user from channels[#channel] array 
    end
  when :mode
    ev_params = event.params.first.split("")
    if event.sender.server? # Parse bot's private modes (ix,..) -- SERVER
      Scarlet::Parser.parse_modes ev_params, @modes
    else # USER/CHAN modes
      mode = true
      event.params.compact!
      if event.params.count > 1 # user list - USER modes
        flags = mode_list.remap { |k,v| [v[:prefix],v[:name].to_sym] }
        operator_count = 0
        nicks = event.params[1..-1]
        ev_params.each_with_index do |flag, i|
          mode = (flag=="+") ? true : (flag == "-" ? false : mode)
          operator_count += 1 and next if flag == "+" or flag == "-" or flag == " "
          nick = nicks[i-operator_count]
          if nick[0] != "#"
            @channels[event.channel][:users][nick][flags[flag]] = mode
          else # this checks for cases like "MODE +v+n Speed #bugs", but there's an error with event.params not including #bugs TODO
            mode ? @channels[event.channel][:flags] << c : @channels[event.channel][:flags].subtract_once(c)
          end
        end
      else # CHAN modes
        Scarlet::Parser.parse_modes ev_params, @channels[event.channel][:flags]
      end
    end
  when :topic # Channel topic was changed
    print_console "#{event.sender.nick} changed #{event.channel} topic to #{event.params.first}", :light_green
  when :error # Either the server acknowledged disconnect, or there was a serious issue with something
    if event.target.start_with? "Closing Link"
      puts "Disconnection from #{@config.address} successful.".blue
    else
      puts "ERROR: #{event.params.join(' ')}".red
    end
  when :cap

    # This will need quite some correcting, but it should work.

    case event.params[0]
    when 'LS'
      event.params[1].split(" ").each {|extension| @cap_extensions[extension] = false}
      # Handshake not yet complete. That means, request extensions!
      if not @handshake
        %w[account-notify extended-join].each do |extension| 
          @cap_extensions[extension] = :processing
          send_data "CAP REQ :#{extension}"
        end
      end
    when 'ACK'
      event.params[1].split(" ").each {|extension| @cap_extensions[extension] = true; puts "#{extension} ENABLED."}
    when 'NAK'
      event.params[1].split(" ").each {|extension| @cap_extensions[extension] = false}
    end
    
    # if the command isn't LS (the first LS sent in the handshake)
    # and no command still needs processing
    send_data "CAP END" if event.params[0] != "LS" && !@handshake && !@cap_extensions.get_values.include?(:processing)
  when :account
    # This is a capability extension for tracking user NickServ logins and logouts
    # event.target is the accountname, * if there is none. This must get executed
    # either way, because either the user logged in, or he logged out. (a change)

    @channels.each {|key, channel| 
      if channel[:users][event.sender.nick]
        channel[:users][event.sender.nick][:ns_login] = event.target != "*" ? true : false
        channel[:users][event.sender.nick][:account_name] = event.target != "*" ? event.target : nil
      end 
    }

  when :"001"
    @handshake = true
    msg "NickServ", "IDENTIFY #{@config.password}", true if @config.password? # login only if a password was supplied
  when :"004"
    @ircd = event.params[1] # grab the name of the ircd that the server is using
  when :"005" # PROTOCTL NAMESX reply with a list of options
    event.params.pop # remove last item (:are supported by this server)
    event.params.each do |segment|
      if s = segment.match(/(?<token>.+)\=(?<parameters>.+)/)
        param = s[:parameters].match(/^[[:digit:]]+$/) ? s[:parameters].to_i : s[:parameters] # convert digit only to digits
        @extensions[s[:token].downcase.to_sym] = param
      else
        @extensions[segment.downcase.to_sym] = true
      end
    end
  when /00\d/ # Login procedure
    print_console event.params.first, :light_green if Scarlet.config.display_logon
  when :'315' # End of /WHO list

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
    @current_nick += "Bot" and send_cmd :nick, :nick => @current_nick # dumb retry, append "Bot" to nick and resend NICK
  when :'353' # NAMES list
    # param[0] --> chantype: "@" is used for secret channels, "*" for private channels, and "=" for public channels.
    # param[1] -> chan, param[2] - users
    event.params[2].split(" ").each {|nick| nick, @channels[event.params[1]][:users][nick] = Parser.parse_names_list self, nick }
  when :'354' # WHOX response
    # There's many different outputs, depending on flags. Right now, we'll just
    # parse those which include 42 (our login checks)

    if event.params.first == '42'
      # 0 - 42, 1 - channel, 2 - nick, 3 - account name (0 if none)
      if event.params[3] != '0'
        @channels[event.params[1]][:users][event.params[2]][:ns_login] = true
        @channels[event.params[1]][:users][event.params[2]][:account_name] = event.params[3]
      end
    else
      print_console "WHOX TODO -- params: #{event.params.inspect};", :yellow
    end
    
  when :'366' # end of /NAMES list
    # After we got our nick list, we want to check their NickServ login stat. 
    # event.params.first <== channel

    # if WHOX is enabled, we can use the a flag to get user's account names
    # if the user has an account name, he is logged in. If he does not have
    # an account name, he is logged out. This is the prefered way to check
    # logins on bot join, as it only needs one message.
    #
    # WHOX - http://hg.quakenet.org/snircd/file/37c9c7460603/doc/readme.who

    if @extensions[:whox]
      send_data "WHO #{event.params.first} %nact,42" # we use the 42 to locally identify login checks
    else
     check_ns_login @channels[event.params.first][:users].keys
    end
  when :'375' # START of MOTD
    # capture and extract the list of possible modes on this network
    hsh = Scarlet.base_mode_list.dup
    prefix2key = hsh.remap{|k,v|[v[:prefix],k]}
    supmodes = @extensions[:prefix].match(/\((\w+)\)(.+)/)[1,2]
    #supmodes[0],supmodes[1] # // :prefix(s), :symbol(s)
    supped = prefix2key.keys & supmodes[0].split("")
    @mode_list = Hash[supped.collect {|prfx| [prefix2key[prfx], hsh[prefix2key[prfx]]] }]
    # this is immediately after 005 messages usually so set up extended NAMES command
    send_data "PROTOCTL NAMESX" if @extensions[:namesx]
  when :'376' # END of MOTD command. Join channel(s)!
    send_cmd :join, :channel => @config.channel
  when /(372|26[56]|25[012345])/ # ignore MOTD and some statuses
  when :'396' # RPL_HOSTHIDDEN - on UnrealIRCd
    # Reply to a user when user mode +x (host masking) was set successfully
    @vHost = event.params.first
    print_console event.params.join(' '), :light_magenta
  when /451/ # You have not registered
    # Something was sent before the USER NICK PASS handshake completed.
    # This is quite useful but we need to ignore it as otherwise ircd's 
    # like ircd-seven (synIRC) cries if we use CAP.
  when /4\d\d/ # Error message range
    return if event.params.join(' ') =~ /CAP Unknown command/ # Ignore bitchy ircd's that can't handle CAP
    print_console event.params.join(' '), :light_red
    msg @channels.keys.join(","), "ERROR: #{event.params.join(' ')}".irc_color(4,0), true
  else # unknown message, print it out as a TODO
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
    write_log :privmsg, message, target
    print_chat @current_nick, message, silent unless silent
  end

  def notice target, message, silent=false
    send_data "NOTICE #{target} :#{message}"
    write_log :notice, message, target
    print_console ">#{target}< #{message}", :light_cyan unless silent
  end

  def write_log command, message, target
    return if target =~ /Serv$/ # if we PM a bot, i.e. for logging in, that shouldn't be logged.
    log = Log.new(:nick => @current_nick, :message => message, :command => command.upcase, :target => target)
    log.channel = target if target.starts_with? "#"
    log.save!
  end

  def check_ns_login nick
    # According to the docs, those servers that use STATUS may query up to
    # 16 nicknames at once. if we pass an Array do:
    #   a) on STATUS send groups of up to 16 nicknames
    #   b) on ACC, we have no such luck, send each message separately.

    if nick.is_a? Array
      if @ircd =~ /unreal/i
        nick.each_slice(16) {|group| msg "NickServ", "STATUS #{group.join(' ')}", true}
      else
        nick.each {|nickname| msg "NickServ", "ACC #{nick}", true}
      end 
    else # one nick was given, send the message
      msg "NickServ", "ACC #{nick}", true if @ircd =~ /ircd-seven/i # freenode
      msg "NickServ", "STATUS #{nick}", true if @ircd =~ /unreal/i
    end


  end
end
end