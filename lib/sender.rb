class IRC
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