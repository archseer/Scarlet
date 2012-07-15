class IRC
  class Sender
    attr_accessor :nick, :username, :host, :user

    def initialize(string)
      if string =~ /^([^!]+)!~?([^@]+)@(.+)$/ # It appears that some networks use a !~ instead of !.
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