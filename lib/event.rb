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

  def reply message, silent=false
    msg return_path, message, silent
  end

  def action msg, silent=false
    msg return_path, "\001ACTION #{msg}\001", silent
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

    def server?
      @server
    end

    def user?
      !@server
    end

    def to_s
      @server ? @host : @nick + '!' + @username + '@' + @host
    end

    def empty?
      to_s.empty?
    end
  end

end