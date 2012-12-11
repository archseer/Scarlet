module Scarlet
  class User
    attr_accessor :name, :ns_login, :channels, :account_name
    alias :nick :name

    def initialize name
      @name = name
      @ns_login = false
      @account_name = nil
      @channels = Channels.new
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id} name=#{@name}, ns_login=#{ns_login}>"
    end

    def join channel
      @channels.add channel
      channel.users.add self
    end

    def part channel
      chan = @channels.remove(channel) # we can pass a string or Channel and it will return a Channel.
      chan.users.remove @name
    end

    def part_all
      @channels.each { |channel| channel.remove_user self }
      @channels.clear
    end
  end

  class Users
    def initialize
      @users = {}
    end

    # gets an user if he exists, else it creates one.
    def get_ensured user
      if exist? user
        get user
      else
        add User.new(user)
      end
    end

    # checks if user exists
    def exist? user
      !!@users[user.to_s]
    end

    def get user
      @users[user.to_s]
    end

    def add user
      @users[user.name] = user
    end

    def remove user
      @users.delete(user.to_s)
    end

    def quit user
      remove(user).part_all
    end

    def clear
      @users.clear
    end

    def each(&block)
      @users.values.each(&block)
    end

    def to_a
      @users.values
    end
  end

end