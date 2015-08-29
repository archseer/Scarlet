class Scarlet
  # Included in all Scarlet plugins.
  module BaseHelper
    # Cuts up a message into chunks of 450 characters, chunks are yieled, instead
    # of returned.
    #
    # @param [String] msg
    # @yieldparam [String]
    def chop_msg msg, &block
      fmt.chop_msg fmt.purify_msg(msg), &block
    end

    # Send data via the server.
    def send_data(data)
      event.server.send data
    end

    def config
      event.server.config
    end

    # Sends a PRIVMG message. Logs the message to the log.
    #
    # @param [String, Symbol] target The target recipient of the message.
    # @param [String] message The message to be sent.
    def msg target, message
      chop_msg message do |m|
        event.server.throttle_send "PRIVMSG #{target} :#{m}"
        event.server.write_log :privmsg, m, target
      end
    end

    # Sends a NOTICE message to +target+. Logs the message to the log.
    #
    # @param [String, Symbol] target The target recipient of the message.
    # @param [String] message The message to be sent.
    def notice target, message
      chop_msg message do |m|
        event.server.throttle_send "NOTICE #{target} :#{m}"
        event.server.write_log :notice, message, target
      end
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
    # @param [*Array] channels A list of channels to join.
    def join *channels
      return if channels.empty?
      send_data "JOIN #{channels.join(',')}"
    end

    # Sends a reply back to where the event came from (a user or a channel).
    # @param [String] message The message to send back.
    def reply(message)
      msg event.return_path, message
    end

    # Sends a NOTICE reply back to the sender (a user).
    # @param [String] message The message to send back.
    def notify(message)
      notice event.sender.nick, message
    end

    # Send a reply back as a ctcp message.
    def ctcp(command, message)
      notify "\001#{command} #{message}\001"
    end

    # Sends a described action back to where the event came from.
    # @param (see #reply)
    def action(message)
      reply "\001ACTION #{message}\001"
    end

    # format module
    def fmt
      Scarlet::Fmt
    end
  end
end
