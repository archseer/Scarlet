class Scarlet
  # Included in all Scarlet plugins.
  module BaseHelper
    # Cuts up a message into chunks of 450 characters, chunks are yieled, instead
    # of returned.
    #
    # @param [String] msg
    # @yieldparam [String]
    def chop_msg msg, &block
      Scarlet::Fmt.chop_msg Scarlet::Fmt.purify_msg(msg), &block
    end

    # Sends a PRIVMG message. Logs the message to the log.
    #
    # @param [String, Symbol] target The target recipient of the message.
    # @param [String] message The message to be sent.
    def msg target, message
      chop_msg message do |m|
        @event.server.throttle_send "PRIVMSG #{target} :#{m}"
        write_log :privmsg, m, target
      end
    end

    # Sends a NOTICE message to +target+. Logs the message to the log.
    #
    # @param [String, Symbol] target The target recipient of the message.
    # @param [String] message The message to be sent.
    def notice target, message
      chop_msg message do |m|
        @event.server.throttle_send "NOTICE #{target} :#{m}"
        write_log :notice, message, target
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
      @event.server.send "JOIN #{channels.join(',')}"
    end

    # format module
    def fmt
      Scarlet::Fmt
    end
  end
end
