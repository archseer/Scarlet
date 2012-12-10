class Scarlet::Event
  attr_accessor :server, :sender, :command, :params, :target, :channel, :return_path

  def initialize server, prefix, command, target, params
    @server = server
    @sender = Sender.new prefix
    #unless @sender.server? and server.users.include? @sender.nick
    #  @sender.user = server.user[@sender.nick]
    #end
    @command = command
    @target = target
    @channel = target if target and target[0, 1] == '#'
    @return_path = @channel ? @channel : @sender.nick
    @params = params
  end

  delegate :msg, :notice, :send, :send_cmd, to: :@server

  # Sends a reply back to where the event came from (a user or a channel).
  def reply message
    msg return_path, message
  end

  # Sends a described action back to where the event came from.
  def action msg
    reply "\001ACTION #{msg}\001"
  end

  class Sender
    attr_accessor :nick, :username, :host, :user

    def initialize(string)
      # username prefixes - In most daemons ~ is prefixed to a non-identd username, n= and i= are rare.
      if string =~ /^([^!]+)!~?([^@]+)@(.+)$/
        @nick, @username, @host = $1, $2, $3
        @server = false
      else
        @host = string
        @server = true
      end
      @user = nil
    end

    # Returns +true+ if sender is a server.
    def server?
      @server
    end

    # Returns +true+ if sender is a user. Functionally equivalent to <tt>!server?</tt>.
    def user?
      !@server
    end

    # Returns a hostmask.
    def to_s
      @server ? @host : "#{@nick}!#{@username}@#{@host}"
    end

    # Returns +true+ if the sender exists.
    def empty?
      to_s.empty?
    end
  end

end