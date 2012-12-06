module Scarlet
class Server
  @@event_handles = {}
  def self.on command,*args,&func
    handles = @@event_handles[command] ||= []
    func = func || proc { nil }
    args.include?(:prepend) ? handles.unshift(func) : handles.push(func)
  end

  on :ping do |event|
    print_console "[ Server ping ]" if Scarlet.config.display_ping
    send_data "PONG :#{event.target}"
  end

  on :pong do |event|
    print_console "[ Ping reply from #{event.sender.host} ]" if Scarlet.config.display_ping
  end

  on :privmsg do |event|
    if event.params.first =~ /\001PING (.+)\001/
      puts "[ CTCP PING from #{event.sender.nick} ]" 
      send_data "NOTICE #{event.sender.nick} :\001PING #{$1}\001"
    elsif event.params.first =~ /\001VERSION\001/
      puts "[ CTCP VERSION from #{event.sender.nick} ]" 
      send_data "NOTICE #{event.sender.nick} :\001VERSION RubyxCube v1.0\001"
    else
      print_chat event.sender.nick, event.params.first
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

      # if we detect a command sequence, we remove the prefix, we execute it.
      # it is prefixed with @config.control_char or by mentioning the bot's current nickname
      if event.params.first =~ /^#{@current_nick}[:,]?\s*/i
        event.params[0] = event.params[0].split[1..-1].join(' ')
        Command.new(self, event.dup)
      elsif event.params.first.starts_with? @config.control_char
        event.params.first.slice!(0)
        Command.new(self, event.dup)
      end
    end
  end

  on :notice do |event|
    # handle NickServ login checks
    if event.sender.nick == "NickServ"
      if ns_params = event.params.first.match(/STATUS\s(?<nick>\S+)\s(?<digit>\d)$/i) || event.params.first.match(/(?<nick>\S+)\sACC\s(?<digit>\d)$/i)
        Users.ns_login self.name, ns_params[:nick] if ns_params[:digit] == "3" && !Users.ns_login?(self.name, ns_params[:nick])
      end
    elsif event.sender.nick == "HostServ"
      event.params.first.match(/Your vhost of \x02(\S+)\x02 is now activated./i) {|host| 
        @vHost = host[1]
        print_console "#{@vHost} is now your hidden host (set by services.)", :light_magenta
      }
    elsif event.sender.nick == "Global" 
      # ignore notices from Global (wallops?)
    else # not from NickServ or HostServ -- normal notice
      print_console "-#{event.sender.nick}-: #{event.params.first}", :light_cyan 
    end
  end

  on :join do |event|
    # :nick!user@host JOIN :#channelname - normal
    # :nick!user@host JOIN #channelname accountname :Real Name - extended-join

    if @current_nick != event.sender.nick
      print_console "#{event.sender.nick} (#{event.sender.username}@#{event.sender.host}) has joined channel #{event.channel}.", :light_yellow
      if !event.params.empty? && @cap_extensions['extended-join']
        # extended-join is enabled, which means that join returns two extra params, 
        # NickServ account name and real name. This means, we don't need to query 
        # NickServ about the user's login status.
        user_name = event.sender.nick
        user = Users.add_user(self.name, user_name)
        Channels.add_user_to_channel(self.name, user_name, event.channel)
        user[:ns_login] = true
        user[:account_name] = event.params[0]
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
      Channels.add_channel(self.name, event.channel)
      send_cmd :mode, :mode => event.channel
      print_console "Joined channel #{event.channel}.", :light_yellow
    end
    user_name = event.sender.nick
    Users.add_user(self.name, user_name)
    Channels.add_user_to_channel(self.name, user_name, event.channel)
  end

  on :part do |event|
    if event.sender.nick == @current_nick
      Channels.remove_channel(self.name, event.channel) # remove chan if bot parted
      print_console "Left channel #{event.channel} (#{event.params.first}).", :light_magenta
    else
      Channels.remove_user_from_channel(self.name, event.sender.nick,event.channel)
      print_console "#{event.sender.nick} has left channel #{event.channel} (#{event.params.first}).", :light_magenta
    end
  end

  on :quit do |event|
    Users.remove_user(self.name, event.sender.nick)
    print_console "#{event.sender.nick} has quit (#{event.target}).", :light_magenta
  end

  on :nick do |event|
    Users.rename_user(self.name, event.sender.nick, event.target)
    if event.sender.nick == @current_nick
      @current_nick = event.target
      print_console "You are now known as #{event.target}.", :light_yellow
    else
      print_console "#{event.sender.nick} is now known as #{event.target}.", :light_yellow
    end
  end

  on :kick do |event|
    messg  = "#{event.sender.nick} has kicked #{event.params.first} from #{event.target}"
    messg += " (#{event.params[1]})" if event.params[1] != event.sender.nick # reason for kick, if given
    messg += "."
    print_console messg, :light_red
    # we process this the same way as a part.
    if event.params.first == @current_nick
      Channels.remove_channel(self.name, event.channel) # if scarlet was kicked, delete that chan's array.
    else
      # remove the kicked user from channels[#channel] array 
      Channels.remove_user_from_channel(self.name, event.params.first, event.target)
    end
  end

  on :mode do |event|
    ev_params = event.params.first.split("")
    if event.sender.server? # Parse bot's private modes (ix,..) -- SERVER
      Parser.parse_modes ev_params, @modes
    else # USER/CHAN modes
      event.params.compact!
      if event.params.count > 1 # user list - USER modes
        event.params[1..-1].each do |nick|
          chan = Channels[self.name, event.channel]
          obj_flags = chan[:user_flags][nick]
          Parser.parse_user_modes ev_params, obj_flags, mode_list          
        end
      else # CHAN modes
        Parser.parse_modes ev_params, @channels[event.channel][:flags]
      end
    end
  end

  on :topic do |event| # Channel topic was changed 
    print_console "#{event.sender.nick} changed #{event.channel} topic to #{event.params.first}", :light_green
  end

  on :error do |event|
    if event.target.start_with? "Closing Link"
      puts "Disconnection from #{@config.address} successful.".blue
    else
      print_error "ERROR: #{event.params.join(' ')}"
    end
  end

  on :cap do |event|
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
      event.params[1].split(" ").each {|extension| @cap_extensions[extension] = true }
    when 'NAK'
      event.params[1].split(" ").each {|extension| @cap_extensions[extension] = false}
    end
    
    # if the command isn't LS (the first LS sent in the handshake)
    # and no command still needs processing
    send_data "CAP END" if event.params[0] != "LS" && !@handshake && !@cap_extensions.values.include?(:processing)    
  end

  on :account do |event|
    # This is a capability extension for tracking user NickServ logins and logouts
    # event.target is the accountname, * if there is none. This must get executed
    # either way, because either the user logged in, or he logged out. (a change)
    user = Users[self.name, event.sender.nick]
    if user
      user[:ns_login] = event.target != "*" ? true : false
      user[:account_name] = event.target != "*" ? event.target : nil
    end    
  end

  on :"001" do |event|
    @handshake = true
    msg "NickServ", "IDENTIFY #{@config.password}", true if @config.password? # login only if a password was supplied
  end

  on :"004" do |event|
    @ircd = event.params[1] # grab the name of the ircd that the server is using
  end

  on :"005" do |event| # PROTOCTL NAMESX reply with a list of options
    event.params.pop # remove last item (:are supported by this server)
    event.params.each do |segment|
      if s = segment.match(/(?<token>.+)\=(?<parameters>.+)/)
        param = s[:parameters].match(/^[[:digit:]]+$/) ? s[:parameters].to_i : s[:parameters] # convert digit only to digits
        @extensions[s[:token].downcase.to_sym] = param
      else
        @extensions[segment.downcase.to_sym] = true
      end
    end
  end

  on :'315' # End of /WHO list

  on :'324' do |event| # Chan mode
    Parser.parse_modes event.params[1].split(''), Channels[self.name, event.params.first][:flags]
  end

  on :'329' do |event| # Channel created at
    print_console "#{event.params[0]} created at #{Time.at(event.params[1].to_i).strftime("%c")}", :light_green
  end

  on :'332' do |event| # Channel topic
    message = "Topic for #{event.params.first} is: #{event.params[1]}"
    print_console message, :light_green
  end  

  on :'333' do |event| # Channel topic set by
    print_console "Topic for #{event.params[0]} set by #{event.params[1]} at #{Time.at(event.params[2].to_i).strftime("%c")}", :light_green
  end

  on :'433' do |event| # Nickname is already in use
    # dumb retry, append "Bot" to nick and resend NICK
    @current_nick += "Bot" and send_cmd :nick, :nick => @current_nick
  end

  on :'353' do |event| # NAMES list
    # param[0] --> chantype: "@" is used for secret channels, "*" for private channels, and "=" for public channels.
    # param[1] -> chan, param[2] - users
    event.params[2].split(" ").each do |nick| 
      user_name, flags = Parser.parse_names_list(mode_list, nick)
      Channels.add_user_to_channel(self.name, user_name,event.params[1])
      channel = Channels[self.name, event.params[1]]
      channel[:user_flags][user_name] = flags
    end  
  end

  on :'354' do |event| # WHOX response
    # There's many different outputs, depending on flags. Right now, we'll just
    # parse those which include 42 (our login checks)

    if event.params.first == '42'
      # 0 - 42, 1 - channel, 2 - nick, 3 - account name (0 if none)
      if event.params[3] != '0'
        user = Users[self.name, event.params[2]]
        if user
          user[:ns_login] = true
          user[:account_name] = event.params[3]
        end
      end
    else
      print_console "WHOX TODO -- params: #{event.params.inspect};", :yellow
    end

  end

  on :'366' do |event| # end of /NAMES list
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
      check_ns_login @channels[event.params.first][:users]
    end
  end  

  on :'375' do |event| # START of MOTD
    # capture and extract the list of possible modes on this network
    hsh = Scarlet.base_mode_list.dup
    prefix2key = hsh.remap{ |k,v| [v[:prefix], k] }
    supmodes = @extensions[:prefix].match(/\((\w+)\)(.+)/)[1, 2]
    #supmodes[0],supmodes[1] # // :prefix(s), :symbol(s)
    supped = prefix2key.keys & supmodes[0].split("")
    @mode_list = Hash[supped.collect { |prfx| [prefix2key[prfx], hsh[prefix2key[prfx]]] }]
    # this is immediately after 005 messages usually so set up extended NAMES command
    send_data "PROTOCTL NAMESX" if @extensions[:namesx]
  end  

  on :'376' do |event| # END of MOTD command. Join channel(s)!
    send_cmd :join, :channel => @config.channel
  end

  on :'396' do |event| # RPL_HOSTHIDDEN - on some ircd's
    # Reply to a user when user mode +x (host masking) was set successfully
    @vHost = event.params.first
    print_console event.params.join(' '), :light_magenta  
  end

  on :all do |event|
    case event.command    
    when /00[0236789]/ # Login procedure
      print_console event.params.first, :light_green if Scarlet.config.display_logon
      true
    when /(372|26[56]|25[012345])/ # ignore MOTD and some statuses
      true
    when /451/ # ERROR: You have not registered
      # Something was sent before the USER NICK PASS handshake completed.
      # This is quite useful but we need to ignore it as otherwise ircd's 
      # like UnrealIRCd (synIRC) cries if we use CAP.
      true
    when /4\d\d/ # Error message range
      unless event.params.join(' ') =~ /CAP Unknown command/ # Ignore bitchy ircd's that can't handle CAP
        print_error event.params.join(' ')
        msg @channels.keys.join(","), "ERROR: #{event.params.join(' ')}".irc_color(4,0), true
      end
      true
    else
      false
    end  
  end

  on :todo do |event|
    print_console "TODO SERV -- sender: #{event.sender.inspect}; command: #{event.command.inspect};
       target: #{event.target.inspect}; channel: #{event.channel.inspect}; params: #{event.params.inspect};", :yellow
  end

  #---handle_event--------------------------------------------
  def handle_event event
    r = @@event_handles[:all].each { |func| instance_exec(event.dup, &func) } # Execute before every other handle
    key = @@event_handles.has_key?(event.command) ? event.command : :todo
    return if r and key == :todo
    @@event_handles[key].each { |func| instance_exec(event.dup, &func) }
  end

end
end