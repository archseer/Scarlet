module Scarlet
  module Handler
    # Contains all of our event listeners.
    @@event_listeners = { all: [] }
    @@ctcp_listeners = { all: [] }

    # Adds a new event listener.
    # @param [Symbol] command The command to listen for.
    # @param [*Array] args A list of arguments.
    # @param [Proc] block The block we want to execute when we catch the command.
    def self.on(command, *args, &block)
      listeners = @@event_listeners[command] ||= []
      block ||= proc { nil }
      args.include?(:prepend) ? listeners.unshift(block) : listeners.push(block)
    end

    # Adds a new ctcp listener.
    # @param [Symbol] command The command to listen for.
    # @param [*Array] args A list of arguments.
    # @param [Proc] block The block we want to execute when we catch the command.
    def self.ctcp(command, *args, &block)
      listeners = @@ctcp_listeners[command] ||= []
      block ||= proc { nil }
      args.include?(:prepend) ? listeners.unshift(block) : listeners.push(block)
    end

    # Passes the event on to any event listeners that are listening for this command.
    # All events get passed to the +:all+ listener.
    # @param [Event] event The event that was recieved.
    def self.handle_event(event)
      execute = lambda { |block| event.server.instance_exec(event.dup, &block) }
      @@event_listeners[:all].each(&execute) # Execute before every other handle
      @@event_listeners[event.command].each(&execute) if @@event_listeners.has_key?(event.command)
    end

    def self.handle_ctcp(event)
      event = Scarlet::DCC::Event.new(event)
      execute = lambda { |block| event.server.instance_exec(event, &block) }
      @@ctcp_listeners[:all].each(&execute) # Execute before every other handle
      @@ctcp_listeners[event.command].each(&execute) if @@ctcp_listeners.has_key?(event.command)
    end

    ctcp :PING do |event|
      puts "[ CTCP PING from #{event.sender.nick} ]"
      event.notify "\001PING #{event.params.first}\001"
    end

    ctcp :VERSION do |event|
      puts "[ CTCP VERSION from #{event.sender.nick} ]"
      event.notify "\001VERSION Scarlet v#{Scarlet::VERSION}\001"
    end

    ctcp :TIME do |event|
      event.notify Time.now.strftime("%a %b %d %H:%M:%S %Z %Y")
    end

    ctcp :DCC do |event|
      Scarlet::DCC.handle_dcc(event)
    end

    on :ping do |event|
      send "PONG :#{event.target}"
    end

    on :pong do |event|
      print_console "[ Ping reply from #{event.sender.host} ]" if Scarlet.config.display_ping
    end

    on :privmsg do |event|
      if event.params.first =~ /\001.+\001/ # It's a CTCP message
        Handler.handle_ctcp(event)
      else

        # check for http:// URL's and output their titles (TO IMPROVE!)
        event.params.first.match(/(http:\/\/[^ ]*)/) do |url|
          begin
            EM::HttpRequest.new(url).get(:redirects => 1).callback do |http|
              http.response.match(/<title>(.*)<\/title>/) do |title|
                event.reply "Title: #{title[1]}" #(domain)
              end
            end
          rescue Exception
          end
        end

        # if we detect a command sequence, we remove the prefix and execute it.
        # it is prefixed with config.control_char or by mentioning the bot's current nickname
        if event.params.first =~ /^#{@current_nick}[:,]?\s*/i
          event.params[0] = event.params[0].split[1..-1].join(' ')
          Command.new(event.dup)
        elsif event.params.first.starts_with? config.control_char
          event.params.first.slice!(0)
          Command.new(event.dup)
        end
      end
    end

    on :notice do |event|
      # handle NickServ login checks
      if event.sender.nick == "NickServ"
        if ns_params = event.params.first.match(/STATUS\s(?<nick>\S+)\s(?<digit>\d)$|(?<nick>\S+)\sACC\s(?<digit>\d)$/i)
          @users.get(ns_params[:nick]).ns_login = true if ns_params[:digit] == "3"
        end
      elsif event.sender.nick == "HostServ"
        event.params.first.match(/Your vhost of \x02(\S+)\x02 is now activated./i) do |host|
          @vHost = host[1]
          print_console "#{@vHost} is now your hidden host (set by services.)", :light_magenta
        end
      end
    end

    on :join do |event|
      # :nick!user@host JOIN :#channelname - normal
      # :nick!user@host JOIN #channelname accountname :Real Name - extended-join

      if @current_nick == event.sender.nick
        @channels.add Channel.new(event.channel)
        send "MODE #{event.channel}"
        print_console "Joined channel #{event.channel}.", :light_yellow
      end

      user = @users.get_ensured(event.sender.nick)
      user.join @channels.get(event.channel)

      if @current_nick != event.sender.nick

        if !event.params.empty? && @cap_extensions['extended-join']
          # extended-join is enabled, which means that join returns two extra params,
          # NickServ account name and real name. This means, we don't need to query
          # NickServ about the user's login status.
          user.ns_login = true
          user.account_name = event.params[0]
        else
          # No luck, we need to manually query for a login check.
          # a) if WHOX is available, query with WHOX.
          # b) if still no luck, query NickServ.
          if @cap_extensions['whox']
            send "WHO #{event.params.first} %nact,42" # we use the 42 to locally identify login checks
          else
            check_ns_login event.sender.nick
          end
        end

      end
    end

    on :part do |event|
      if event.sender.nick == @current_nick
        @channels.remove @channels.get(event.channel) # remove chan if bot parted
      else
        event.sender.user.part @channels.get(event.channel)
      end
    end

    on :quit do |event|
      @users.remove(event.sender.user)
      event.sender.user.part_all
    end

    on :nick do |event|
      event.sender.user.nick = event.target
      if event.sender.nick == @current_nick
        @current_nick = event.target
        print_console "You are now known as #{event.target}.", :light_yellow
      end
    end

    on :kick do |event|
      messg  = "#{event.sender.nick} has kicked #{event.params.first} from #{event.target}"
      messg += " (#{event.params[1]})" if event.params[1] != event.sender.nick # reason for kick, if given
      messg += "."
      print_console messg, :light_red
      # we process this the same way as a part.
      if event.params.first == @current_nick
        @channels.remove(event.channel) # if scarlet was kicked, delete that chan's array.
      else
        # remove the kicked user from channels[#channel] array
        @users.get(event.params.first).part(event.channel)
      end
    end

    on :mode do |event|
      ev_params = event.params.first.split('')
      if event.target == @current_nick # Parse bot's private modes (ix,..) - self is the target of the event.
        Parser.parse_modes ev_params, @modes
      else # USER/CHAN modes
        event.params.compact!
        if event.params.count > 1 # user list - USER modes on CHAN (event.target/event.channel)
          event.params[1..-1].each do |nick|
            chan = @channels.get(event.channel)
            user = @users.get_ensured(nick)
            chan.user_flags[user] ||= {}
            @parser.parse_user_modes ev_params, chan.user_flags[user]
          end
        else # CHAN modes
          Parser.parse_modes ev_params, @channels.get(event.channel).modes
        end
      end
    end

    on :topic do |event| # Channel topic was changed
      @channels.get(event.channel).topic = event.params.first
    end

    on :error do |event|
      if event.target.start_with? "Closing Link"
        puts "Disconnection from #{config.address} successful.".blue
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
        if @state == :connecting
          # get an array of extensions we want and that server supports
          ext = (%w[multi-prefix account-notify extended-join sasl] & @cap_extensions.keys)
          send "CAP REQ :#{ext.join(' ')}"
        end
      when 'ACK'
        event.params[1].split(' ').each {|extension| @cap_extensions[extension] = true }

        if @cap_extensions['sasl'] && config.sasl
          send_sasl
        else
          send "CAP END"
        end
      when 'NAK'
        event.params[1].split(' ').each {|extension| @cap_extensions[extension] = false}
        send "CAP END"
      end

    end

    on :authenticate do |event| # SASL AUTHENTICATE
      send "AUTHENTICATE #{@sasl.generate(config.nick, config.password, event.target)}"
    end

    on :account do |event|
      # This is a capability extension for tracking user NickServ logins and logouts
      # event.target is the accountname, * if there is none. This must get executed
      # either way, because either the user logged in, or he logged out. (a change)
      if user = event.sender.user
        user.ns_login = event.target != "*" ? true : false
        user.account_name = event.target != "*" ? event.target : nil
      end
    end

    on :'001' do |event| # RPL_WELCOME - First message sent after client registration.
      @state = :connected
      # login only if a password was supplied and SASL wasn't used
      msg 'NickServ', "IDENTIFY #{config.password}" if config.password && !@sasl
    end

    on :'004' do |event|
      @ircd = event.params[1] # grab the name of the ircd that the server is using
    end

    on :'005' do |event| # PROTOCTL NAMESX reply with a list of options
      event.params.pop # remove last item (:are supported by this server)
      @extensions.merge! Parser.parse_isupport(event.params)
    end

    on :'315' # End of /WHO list

    on :'324' do |event| # RPL_CHANNELMODEIS - Channel mode
      Parser.parse_modes event.params[1].split(''), @channels.get(event.params.first).modes
    end

    on :'332' do |event| # Channel topic
      @channels.get(event.params.first).topic = event.params[1]
    end


    on :'353' do |event| # NAMES list
      # param[0] --> chantype: "@" is used for secret channels, "*" for private channels, and "=" for public channels.
      # param[1] -> chan, param[2] - users
      event.params[2].split(' ').each do |nick|
        user_name, flags = @parser.parse_names_list(nick)
        user = @users.get_ensured(user_name)
        channel = @channels.get(event.params[1])
        user.join channel
        channel.user_flags[user] = flags
      end
    end

    on :'354' do |event| # WHOX response
      # There's many different outputs, depending on flags. Right now, we'll just
      # parse those which include 42 (our login checks)

      if event.params.first == '42'
        # 0 - 42, 1 - channel, 2 - nick, 3 - account name (0 if none)
        if event.params[3] != '0'
          if user = @users.get(event.params[2])
            user.ns_login = true
            user.account_name = event.params[3]
          end
        end
      else
        print_console "WHOX TODO -- params: #{event.params.inspect};", :yellow
      end

    end

    on :'366' do |event| # end of /NAMES list
      # After we got our NAMES list, we want to check their NickServ login stat.
      # event.params.first <== channel

      # if WHOX is enabled, we can use the 'a' flag to get user's account names
      # if the user has an account name, he is logged in. This is the prefered
      # way to check logins on bot join, as it only needs one message.
      #
      # WHOX - http://hg.quakenet.org/snircd/file/37c9c7460603/doc/readme.who

      if @extensions[:whox]
        send "WHO #{event.params.first} %nact,42" # we use the 42 to locally identify login checks
      else
        check_ns_login @channels.get(event.params.first).users.map(&:name)
      end
    end

    on :'375' do |event| # START of MOTD - immediately after 005 messages
      # create a new parser that uses the list of possible modes on this network.
      @parser = Parser.new(@extensions[:prefix])
      # set up CAP extension multi-prefix the legacy way if it doesn't support CAP
      send "PROTOCTL NAMESX" if @extensions[:namesx]
    end

    on :'376' do |event| # END of MOTD command. Join channel(s)! (if any)
      join *config.channels unless config.channels.empty?
    end

    on :'396' do |event| # RPL_HOSTHIDDEN - on some ircd's sent when user mode +x (host masking) was set
      @vHost = event.params.first
      print_console event.params.join(' '), :light_magenta
    end

    on :'433' do |event| # ERR_NICKNAMEINUSE - Nickname is already in use
      # dumb retry, append "Bot" to nick and resend NICK
      @current_nick += 'Bot' and send "NICK #{@current_nick}"
    end

    on :'903' do |event| # SASL authentification successful
      puts "[SASL] Auth with #{@sasl.mechanism_name} successful".light_green
      send "CAP END"
    end

    on :'904' do |event| # SASL mechanism failed
      puts "[SASL] Auth with #{@sasl.mechanism_name} failed".light_red
      send_sasl
    end

    on :all do |event|
      case event.command
      when /451/ # ERROR: You have not registered
        # Something was sent before the USER NICK PASS handshake completed.
        # This is quite useful but we need to ignore it as otherwise ircd's
        # that don't support CAP, trigger this if we use CAP.
      when /439/
        # Rizon:
        #  439 * :Please wait while we process your connection.
        # Ignore.
      when /4\d\d/ # Error message range
        unless event.params.join(' ') =~ /CAP Unknown command/ # Ignore bitchy ircd's that can't handle CAP
          print_error event.params.join(' ')
        end
      end
    end
  end
end
