class IrcBot::Bot < EM::Connection
  attr_accessor :scheduler, :log, :data_log, :disconnecting

  def post_init
    path = File.dirname(__FILE__)
    @log = Logger.new("#{path}/../logs/irc.log", 'daily')
    @chan_log = []
    @data_log = Logger.new("#{path}/../logs/server_data.log", 'daily')
    @log.info "\n**** NEW SESSION at #{Time.now}"
    @data_log.info "\n**** NEW SESSION at #{Time.now}"

    @scheduler = Scheduler.new
    @user_commands = YAML.load_file("#{path}/../commands.yml").symbolize_keys!
    @users = {}
    @channels = {}
    @banned = []
    @modes = []
    @disconnecting = false
    connect
  end

  def connect
    client_command :nick, :nick => $config.irc_bot.nick
    client_command :user, :host => $config.irc_bot.host, :nick => $config.irc_bot.nick, :name => $config.irc_bot.name
  end

  def unbind
    puts "DEBUG: Socket has unbound.".red
    if !@disconnecting
      print_console "Connection to server lost.", :light_red
      Modules.restart_mod :IrcBot
    end
  end

  def send_data data
    super "#{data}\r"
  end

  def receive_data data
    return if @disconnecting
    data.split(/\n(?=\:)/).each {|message|
      message.chomp!
      return if message.blank?
      @data_log.info message
      reactor message
    }
  end
 #---main message reactor loop-------------------------------
  def reactor message
    if v = message.match(/^PING :(?<str>.+)$/i) # ping
      puts("[ Server ping ]") if $config.irc_bot.display_ping
      send_data "PONG :#{v[:str]}"
    elsif v = message.match(/:(?<nick>.+?)!(?<hostname>.+?)@(?<host>.+?)\s(?<command>\S+)(?:\s(?<target>#?\S+?))?\s:?(?<parameter>.+?)$/)
      #user/bot sent messages
      user_message_loop v
    elsif v = message.match(/:(?<server>\S+)\s(?<command>\S+)\s(?<type>#?\S+?)\s(?:\:)?(?<parameter>.+?)$/)
      # server messages (incl. numeric)
      server_message_loop v
    end
  end
 #----user message reactor loop------------------------------
  def user_message_loop v
    case v[:command]
      when "PRIVMSG"
        #roughly match CTCP: PING and VERSION
        if v[:parameter] =~ /\001PING (.+)\001/
          puts "[ CTCP PING from #{v[:nick]} ]"
          send_data "NOTICE #{v[:nick]} :\001PING #{$1}\001"
          return
        elsif v[:parameter] =~ /\001VERSION\001/
          puts "[ CTCP VERSION from #{v[:nick]} ]"
          send_data "NOTICE #{v[:nick]} :\001VERSION Rubyista v0.8\001"
          return
        end
        print_chat v[:nick], v[:parameter]
        #process privmsg command if control char was detected
        privmsg_reactor v if v[:parameter][0] == $config.irc_bot.control_char
      when "NOTICE" #Automatic replies must never be sent in response to a NOTICE message.
        if v[:nick] == "NickServ" && ns_params = v[:parameter].match(/(?:ACC|STATUS)\s(?<nick>\S+)\s(?<digit>\d)$/i)
          if ns_params[:digit] == "3"
            #@users[ns_params[:nick]][:ns_login] = true
            @channels.keys.each {|key|
              @channels[key][:users][ns_params[:nick]][:ns_login] = true
            }
            #notice ns_params[:nick], "#{ns_params[:nick]}, you are now logged in with #{$config.irc_bot.nick}." if !::IrcBot::Nick.where(:nick => ns_params[:nick]).empty?
          end
        else
          print_console "NOTICE from #{v[:nick]}: #{v[:parameter]}", :light_cyan if v[:nick] != "Global" #hack
        end
      when "MODE"
        chan = v[:target].gsub('#', '').to_sym
        @channels[chan][:users], @channels[chan][:flags] = ::IrcBot::Parser.parse_mode(v[:parameter], @channels[chan][:users], @channels[chan][:flags])
      when "JOIN"
        chan = v[:parameter].gsub('#', '').to_sym
        if $config.irc_bot.nick != v[:nick]
          print_console "#{v[:nick]} (#{v[:hostname]}@#{v[:host]}) has joined channel #{v[:parameter]}", :light_yellow
          check_nick_login v[:nick]
        else
          @channels[chan] = {:users => {}, :flags => []}
          send_data "MODE #{v[:parameter]}"
          print_console "Joined channel #{v[:parameter]}", :light_yellow
        end
        @channels[chan][:users][v[:nick]] = {}
      when "PART"
        print_console "#{v[:nick]} has left channel #{v[:target]} (#{v[:parameter]})", :light_magenta
        chan = v[:parameter].gsub('#', '').to_sym
        @channels.delete chan if v[:nick] == $config.irc_bot.nick # remove chan if bot parted
        @channels[chan][:users].delete v[:nick]
      when "QUIT"
        print_console "#{v[:nick]} has quit (#{v[:parameter]})", :light_magenta
        @channels.keys.each {|key| key[:users].delete v[:nick]}
      when "NICK"
        @channels.keys.each {|key| @channels[key][:users].rename_key!(v[:nick], v[:parameter])}
        if v[:nick] == $config.irc_bot.nick && $config.irc_bot.nick != v[:parameter]
          print_console "You are now known as #{v[:parameter]}", :light_yellow
          $config.irc_bot.nick = v[:parameter]
        else
          print_console "#{v[:nick]} is now known as #{v[:parameter]}", :light_yellow
        end
    end
  end
 #----server message reactor loop---------------------------
  def server_message_loop v
    case v[:command]
      when "NOTICE" # Automatic replies must never be sent in response to a NOTICE message.
        print_console "#{v[:parameter]}", :light_cyan
      when "PONG"
        puts "[ Ping reply from #{v[:server]} ]"
      when "MODE"
        if v[:type] == $config.irc_bot.nick
          @modes = ::IrcBot::Parser.parse_serv_mode(v[:parameter], @modes)
        else
          puts "ERROR: MODE CANNOT PARSE!".red
        end
      when "001"
        msg "nickserv", "IDENTIFY #{$config.irc_bot.password}", true
      when "005"
        $config.irc_bot.extensions.merge! ::IrcBot::Parser.extentions_parse(v[:parameter])
      when /00\d/
        print_console v[:parameter], :light_green if $config.irc_bot.display_logon
      when "324" # MODE for #channel
        t = v[:parameter].split(" ")
        chan = t[0].gsub('#', '').to_sym
        @channels[chan][:flags] = ::IrcBot::Parser.parse_serv_mode(t[1], @channels[chan][:flags])
      when "329"
        params = v[:parameter].match(/(?<chan>#\S+)\s(?<parameter>.+)$/)
        print_console "#{params[:chan]} created at #{Time.at(params[:parameter].to_i).std_format}", :light_green
      when "332" # MOTD
        params = v[:parameter].split(":")
        message = "Topic for #{params[0].strip!} is: " + params.drop(1).join(":")
        print_console message, :light_green
      when "333" # MOTD set by
        params = v[:parameter].split(" ")
        print_console "Topic for #{params[0]} set by #{params[1]} at #{Time.at(params[2].to_i).std_format}", :light_green
      when "353" # users on channel
        data = v[:parameter].match(/(?<chantype>[\=\@\*])\s(?<target>#?\S+)\s:(?<nicklist>.+)$/) 
        # chantype:  "@" is used for secret channels, "*" for private channels, and "=" for others (public channels).
        chan = data[:target].gsub('#', '').to_sym
        data[:nicklist].split(" ").each { |nick| nick, @channels[chan][:users][nick] = ::IrcBot::Parser.parse_names_list nick }
      when "366" # end of /NAMES list
        #check users already on chan permissions
        d = v[:parameter].match(/(?<target>#?\S+) :End of \/NAMES list./)
        p d[:target]
        chan = d[:target].gsub('#', '').to_sym
        @channels[chan][:users].keys.each { |nick| check_nick_login nick if nick != $config.irc_bot.nick}
      when "375" # START of MOTD
        # this is immediately after 005 messages usually so
        send_data "PROTOCTL NAMESX" if $config.irc_bot.extensions.namesx # set up extended NAMES command
      when "376" # END of MOTD command. Join channel!
        client_command :join, :channel => $config.irc_bot.channel
      when /4\d\d/ # Error messages range
        print_console v[:parameter], :light_red
        msg $config.irc_bot.channel, "ERROR: #{v[:parameter]}".irc_color(4,0), true #TODO: Output only certain messages to channel.
      when /(372|26[56]|25[1245])/ #MOTD command (ignore) + some server info
      else # Anything not implemented will show up as this.
        print_console "TODO SERV -- #{v[:command]}: #{v[:parameter]}", :yellow
    end
  end
 #----privmsg reactor -------------------------------------
  def privmsg_reactor v
    command  = v[:parameter].split[0...1].join(' ')
    sequence = v[:parameter].split(' ').drop(1).join(' ')
    cmd = ::IrcBot::Commands[command[1..-1].to_sym]
    if cmd && !cmd[:disable] && !@banned.include?(v[:nick]) # command exists, not disabled and user not banned
      if cmd[:access_level].nil_zero? # no access level, just execute the function
        self.instance_exec sequence, v, &cmd[:method] # execute it
      else # it requires permissions
        nick = ::IrcBot::Nick.where(:nick => v[:nick])
        ns_login = false
        @channels.each {|key, val| 
          ns_login = val[:users][v[:nick]][:ns_login] if val[:users][v[:nick]][:ns_login]
        } #it will get set to true if at least one chan detects login. hax
        if !ns_login # user was not logged in
          notice v[:nick], "#{v[:nick]}, you are not logged in!"
        elsif nick.count > 0 && nick.first.privileges >= cmd[:access_level] # nick exists and privileges grant access
          self.instance_exec sequence, v, &cmd[:method]
        end
      end
    end
  rescue(Exception) => result
    msg $config.irc_bot.channel, "ERROR: #{result.message}".irc_color(4,0)
  end
  #----------------------------------------------------------

  def client_command cmd, hash
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

  def sched_msg(time,str)
    @scheduler.in time do
      msg $config.irc_bot.channel, str if !str.blank?
    end
  end

  def create_table array, width
    arry = []
    temp = []
    array.each {|line| temp << line.word_wrap(width-5)}
    temp.flatten!
    temp.each_with_index { |line, i|
      arry << (i == 0 ? line.align(width, :center).irc_color(0,1) : line.align(width).irc_color(1,15))
    }
    return arry
  end

  def print_chat nick, message, silent=false
    msg = ::IrcBot::Parser.parse_esc_codes message
    time = "[#{Time.now.strftime("%H:%M")}]"
    if msg =~ /\x01ACTION\s(.+)\x01/ #detect '/me'
      puts "#{time} * #{nick} #{$1}".light_blue if !silent
      @log.info "#{time} * #{nick} #{$1}"
    else
      puts "#{time.light_white} <#{nick.light_red}> #{msg}" if !silent
      @log.info "#{time} <#{nick}> #{::IrcBot::Parser.parse_esc_codes message, true}"
    end
  end

  def print_console message, color=nil
    msg = ::IrcBot::Parser.parse_esc_codes message
    msg = "[#{Time.now.strftime("%H:%M")}] #{msg}"
    puts color ? msg.colorize(color) : msg
    @log.info ::IrcBot::Parser.parse_esc_codes message, true
  end
end