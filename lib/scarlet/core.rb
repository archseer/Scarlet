require 'scarlet/plugin'
require 'scarlet/listeners'

class Scarlet
  class Core
    include Scarlet::Plugin
    # Contains all of our event listeners.
    @@ctcp_listeners = Listeners.new

    # Adds a new ctcp listener.
    # @param [Symbol] command The command to listen for.
    # @param [*Array] args A list of arguments.
    # @param [Proc] block The block we want to execute when we catch the command.
    def self.ctcp(command, *args, &block)
      @@ctcp_listeners.on(command, *args, &block)
    end

    # @param [Event] event
    def self.handle_ctcp(event)
      event = Scarlet::DCC::Event.new(event)
      execute = lambda { |block| event.server.instance_exec(event, &block) }
      @@ctcp_listeners.each_listener(event.command, &execute)
    end

    ctcp :PING do |event|
      logger.info "[ CTCP PING from #{event.sender.nick} ]"
      event.ctcp :PING, event.params.first
    end

    ctcp :VERSION do |event|
      logger.info "[ CTCP VERSION from #{event.sender.nick} ]"
      event.ctcp :VERSION, "Scarlet v#{Scarlet::VERSION}"
    end

    ctcp :TIME do |event|
      event.notify Time.now.strftime("%a %b %d %H:%M:%S %Z %Y")
    end

    ctcp :DCC do |event|
      Scarlet::DCC.handle_dcc(event)
    end

    on :ping do |event|
      send_data "PONG :#{event.target}"
    end

    on :pong do |event|
      logger.info "[ Ping reply from #{event.sender.host} ]"
    end

    on :privmsg do |event|
      Core.handle_ctcp(event) if event.params.first =~ /\001.+\001/ # It's a CTCP message
    end

    on :notice do |event|
      if event.sender.nick == "HostServ"
        event.params.first.match(/Your vhost of \x02(\S+)\x02 is now activated./i) do |host|
          event.server.vHost = host[1]
          logger.info "#{event.server.vHost} is now your hidden host (set by services.)"
        end
      end
    end

    on :join do |event|
      # :nick!user@host JOIN :#channelname - normal
      # :nick!user@host JOIN #channelname accountname :Real Name - extended-join

      if event.server.current_nick == event.sender.nick
        event.server.channels.add Channel.new(event.channel)
        send_data "MODE #{event.channel}"
        logger.info "--> #{event.channel}"
      end

      user = event.server.users.get_ensured(event.sender.nick)
      user.join event.server.channels.get(event.channel)
    end

    on :part do |event|
      if event.sender.nick == event.server.current_nick
        event.server.channels.remove event.server.channels.get(event.channel) # remove chan if bot parted
        logger.info "<-- #{event.channel}"
      else
        event.sender.user.part event.server.channels.get(event.channel)
      end
    end

    on :quit do |event|
      event.server.users.remove(event.sender.user)
      event.sender.user.part_all
    end

    on :nick do |event|
      event.sender.user.nick = event.target
      if event.sender.nick == event.server.current_nick
        event.server.current_nick = event.target
        logger.info "You are now known as #{event.target}."
      end
    end

    on :kick do |event|
      messg  = "#{event.sender.nick} has kicked #{event.params.first} from #{event.target}"
      messg += " (#{event.params[1]})" if event.params[1] != event.sender.nick # reason for kick, if given
      messg += "."
      logger.warn messg
      # we process this the same way as a part.
      if event.params.first == event.server.current_nick
        event.server.channels.remove(event.channel) # if scarlet was kicked, delete that chan's array.
      else
        # remove the kicked user from channels[#channel] array
        event.server.users.get(event.params.first).part(event.channel)
      end
    end

    on :mode do |event|
      ev_params = event.params.first.split('')
      if event.target == event.server.current_nick # Parse bot's private modes (ix,..) - self is the target of the event.
        Parser.parse_modes ev_params, event.server.modes
      else # USER/CHAN modes
        event.params.compact!
        if event.params.count > 1 # user list - USER modes on CHAN (event.target/event.channel)
          event.params[1..-1].each do |nick|
            chan = event.server.channels.get(event.channel)
            user = event.server.users.get_ensured(nick)
            chan.user_flags[user] ||= {}
            event.server.parser.parse_user_modes ev_params, chan.user_flags[user]
          end
        else # CHAN modes
          Parser.parse_modes ev_params, event.server.channels.get(event.channel).modes
        end
      end
    end

    on :topic do |event| # Channel topic was changed
      event.server.channels.get(event.channel).topic = event.params.first
    end

    on :error do |event|
      if event.target.start_with? "Closing Link"
        logger.info "Disconnection from #{config.address} successful."
      else
        logger.error "ERROR: #{event.params.join(' ')}"
      end
    end

    on :cap do |event|
      # This will need quite some correcting, but it should work.
      case event.params[0]
      when 'LS'
        event.params[1].split(" ").each {|extension| event.server.cap_extensions[extension] = false}
        # Handshake not yet complete. That means, request extensions!
        if event.server.state == :connecting
          # get an array of extensions we want and that server supports
          ext = (%w[multi-prefix account-notify extended-join sasl] & event.server.cap_extensions.keys)
          send_data "CAP REQ :#{ext.join(' ')}"
        end
      when 'ACK'
        event.params[1].split(' ').each {|extension| event.server.cap_extensions[extension] = true }

        if event.server.cap_extensions['sasl'] && config.sasl
          event.server.send_sasl
        else
          send_data "CAP END"
        end
      when 'NAK'
        event.params[1].split(' ').each {|extension| event.server.cap_extensions[extension] = false}
        send_data "CAP END"
      end
    end

    on :authenticate do |event| # SASL AUTHENTICATE
      send_data "AUTHENTICATE #{event.server.sasl.generate(config.nick, config.nickserv_password, event.target)}"
    end

    on :'001' do |event| # RPL_WELCOME - First message sent after client registration.
      event.server.state = :connected
      # login only if a password was supplied and SASL wasn't used
      pass = config.nickserv_password
      msg 'NickServ', "IDENTIFY #{pass}" if pass && !event.server.sasl
    end

    on :'004' do |event|
      event.server.ircd = event.params[1] # grab the name of the ircd that the server is using
    end

    on :'005' do |event| # PROTOCTL NAMESX reply with a list of options
      event.params.pop # remove last item (:are supported by this server)
      event.server.extensions.merge! Parser.parse_isupport(event.params)
    end

    on :'315' # End of /WHO list

    on :'324' do |event| # RPL_CHANNELMODEIS - Channel mode
      Parser.parse_modes event.params[1].split(''), event.server.channels.get(event.params.first).modes
    end

    on :'332' do |event| # Channel topic
      event.server.channels.get(event.params.first).topic = event.params[1]
    end

    on :'353' do |event| # NAMES list
      # param[0] --> chantype: "@" is used for secret channels, "*" for private channels, and "=" for public channels.
      # param[1] -> chan, param[2] - users
      event.params[2].split(' ').each do |nick|
        user_name, flags = event.server.parser.parse_names_list(nick)
        user = event.server.users.get_ensured(user_name)
        channel = event.server.channels.get(event.params[1])
        user.join channel
        channel.user_flags[user] = flags
      end
    end

    on :'375' do |event| # START of MOTD - immediately after 005 messages
      # create a new parser that uses the list of possible modes on this network.
      event.server.parser = Parser.new(event.server.extensions[:prefix])
      # set up CAP extension multi-prefix the legacy way if it doesn't support CAP
      send_data "PROTOCTL NAMESX" if event.server.extensions[:namesx]
    end

    on :'376' do |event| # END of MOTD command. Join channel(s)! (if any)
      join *config.channels
    end

    on :'396' do |event| # RPL_HOSTHIDDEN - on some ircd's sent when user mode +x (host masking) was set
      event.server.vHost = event.params.first
      logger.info event.params.join(' ')
    end

    on :'433' do |event| # ERR_NICKNAMEINUSE - Nickname is already in use
      # dumb retry, append "Bot" to nick and resend NICK
      event.server.current_nick += 'Bot' and
        send_data "NICK #{event.server.current_nick}"
    end

    on :'903' do |event| # SASL authentification successful
      puts "[SASL] Auth with #{event.server.sasl.mechanism_name} successful".light_green
      send_data "CAP END"
    end

    on :'904' do |event| # SASL mechanism failed
      logger.error "[SASL] Auth with #{event.server.sasl.mechanism_name} failed"
      event.server.send_sasl
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
          logger.error event.params.join(' ')
        end
      end
    end
  end
end
