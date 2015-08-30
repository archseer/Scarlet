require 'scarlet/plugin'

module Scarlet::Plugins
  # Implements tracking whether the user is logged into their account with
  # NickServ consistently.
  # Implemented as per notes in
  # http://ircv3.net/specs/extensions/account-notify-3.1.html
  class AccountNotify
    include Scarlet::Plugin

    # NOTE: needed CAP extensions are requested in Scarlet::Core#cap
    # TODO: add a state machine for managing CAP, as well as hooks

    # Sends a login check to NickServ, to check whether user(s) are logged in.
    # @param [Array] nicks The nicks to check.
    def check_ns_login *nicks
      # According to the docs, those servers that use STATUS may query up to
      # 16 nicknames at once.
      #  a) on STATUS send groups of up to 16 nicknames.
      #  b) on ACC, we have no such luck, send each message separately.
      case ircd
      when /unreal|hybrid/i # synIRC (unreal), Rizon (hybrid)
        nicks.each_slice(16) { |group| msg "NickServ", "STATUS #{group.join(' ')}" }
      when  /ircd-seven/i # freenode (ircd-seven)
        nicks.each { |nick| msg "NickServ", "ACC #{nick}" }
      else
        raise "Unknown IRCd #{ircd}!"
      end
    end

    on :account do |event|
      # This is a capability extension for tracking user NickServ logins and logouts
      # event.target is the accountname, * if there is none. This must get executed
      # either way, because either the user logged in, or he logged out. (a change)
      if user = sender.user
        user.ns_login = event.target != "*" ? true : false
        user.account_name = event.target != "*" ? event.target : nil
      end
    end

    on :'366' do |event| # end of /NAMES list
      # After we got our NAMES list, we want to check their NickServ login stat.
      # params.first <== channel

      # if WHOX is enabled, we can use the 'a' flag to get user's account names
      # if the user has an account name, he is logged in. This is the prefered
      # way to check logins on bot join, as it only needs one message.
      #
      # WHOX - http://hg.quakenet.org/snircd/file/37c9c7460603/doc/readme.who

      if server.extensions[:whox]
        send_data "WHO #{params.first} %nact,42" # we use the 42 to locally identify login checks
      else
        check_ns_login server.channels.get(params.first).users.map(&:name)
      end
    end

    on :'354' do |event| # WHOX response
      # There's many different outputs, depending on flags. Right now, we'll just
      # parse those which include 42 (our login checks)

      if params.first == '42'
        # 0 - 42, 1 - channel, 2 - nick, 3 - account name (0 if none)
        if params[3] != '0'
          if user = server.users.get(params[2])
            user.ns_login = true
            user.account_name = params[3]
          end
        end
      else
        logger.warn "WHOX TODO -- params: #{params.inspect};"
      end
    end

    on :join do |event|
      # :nick!user@host JOIN :#channelname - normal
      # :nick!user@host JOIN #channelname accountname :Real Name - extended-join

      user = server.users.get_ensured(sender.nick)

      if server.current_nick != sender.nick
        if !params.empty? && server.cap_extensions['extended-join']
          # extended-join is enabled, which means that join returns two extra params,
          # NickServ account name and real name. This means, we don't need to query
          # NickServ about the user's login status.
          user.ns_login = true
          user.account_name = params[0]
        else
          # No luck, we need to manually query for a login check.
          # a) if WHOX is available, query with WHOX.
          # b) if still no luck, query NickServ.
          if server.cap_extensions['whox']
            server.send "WHO #{params.first} %nact,42" # we use the 42 to locally identify login checks
          else
            check_ns_login sender.nick
          end
        end
      end
    end

  end
end
