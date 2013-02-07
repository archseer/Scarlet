# Event is a class that represents a parsed event recieved from the server.
# It contains the basic information of the sender of the event, where it was
# sent from, and what was sent. 
class Scarlet::Event
  attr_accessor :server, :sender, :command, :params, :target, :channel, :return_path

  # Creates a new event that can then be distributed to the listeners.
  # @param [Server] server The server from which the event was sent.
  # @param [String] prefix The hostmask prefix used to generate a Sender.
  # @param [Symbol] command The command the event carries.
  # @param [String] target Whom the event targets.
  # @param [Array] params An array of params for the event.
  def initialize server, prefix, command, target, params
    @server = server
    @sender = Sender.new prefix
    unless @sender.server?
      @sender.user = server.users.get(@sender.nick)
    end
    @command = command.downcase.to_sym
    @target = target
    @channel = target if target and target[0] == '#'
    @return_path = @channel ? @channel : @sender.nick
    @params = params
  end

  # Delegated back to +@server+.
  delegate :msg, :notice, :send, to: :@server

  # Sends a reply back to where the event came from (a user or a channel).
  # @param [String] message The message to send back.
  def reply message
    msg return_path, message
  end

  # Sends a described action back to where the event came from.
  # @param (see #reply)
  def action message
    reply "\001ACTION #{message}\001"
  end

  # A representation of the message sender, created from the hostmask.
  class Sender
    attr_accessor :nick, :username, :host, :user

    # Creates a new instance of Sender, parsing the hostmask.
    # @param [String] hostmask The hostmask to parse the user from.
    def initialize hostmask
      # hostmask prefixes - In most daemons ~ is prefixed to a non-identd username, n= and i= are rare.
      if hostmask =~ /^([^!]+)!~?([^@]+)@(.+)$/
        @nick, @username, @host = $1, $2, $3
        @server = false
      else
        @host = hostmask
        @server = true
      end
      @user = nil
    end

    # Checks if sender is a server.
    # @return [Boolean] +true+ if sender is a server, otherwise false.
    def server?
      @server
    end

    # Checks if sender is a user. Functionally equivalent to <tt>!server?</tt>.
    # @return [Boolean] +true+ if sender is a user, otherwise false.
    def user?
      !@server
    end

    # Returns a hostmask of the sender.
    # @return [String] A hostmask.
    def to_s
      @server ? @host : "#{@nick}!#{@username}@#{@host}"
    end

    # Returns +true+ if the sender exists.
    # @return [Boolean] +true+ if the sender exists.
    def empty?
      to_s.empty?
    end
  end

end