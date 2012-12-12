module Scarlet
  # A representation of a user on an IRC network.
  class User
    attr_accessor :name, :ns_login, :channels, :account_name
    alias :nick :name

    # @param [String] name The name of the user.
    def initialize name
      @name = name
      @ns_login = false
      @account_name = nil
      @channels = Channels.new
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id} name=#{@name}, ns_login=#{ns_login}>"
    end

    # Add the user to a channel.
    # @param [Channel] channel The channel we want to join.
    def join channel
      @channels.add channel
      channel.users.add self
    end

    # Remove the user from a channel.
    # @param [Channel] channel The channel we want to part.
    def part channel
      chan = @channels.remove(channel) # we can pass a string or Channel and it will return a Channel.
      chan.users.remove @name
    end

    # Remove the user from all channels.
    def part_all
      @channels.each { |channel| channel.remove_user self }
      @channels.clear
    end
  end

  # Represents a list we use as a storage for a collection of users.
  class Users
    def initialize
      @users = {}
    end

    # Gets an user if he exists, else it creates one.
    # @param [String] user The user we are looking for.
    def get_ensured user
      if exist? user
        get user
      else
        add User.new(user)
      end
    end

    # Checks if user exists.
    # @param [String] user The user we are looking for.
    def exist? user
      !!@users[user.to_s]
    end

    # Returns the user we query for.
    # @param [String] user The user we are looking for.
    # @return [User, nil] The user, or nil if no such user exists.
    def get user
      @users[user.to_s]
    end

    # Adds a user to the list.
    # @param [User] user The user we are adding to the list.
    def add user
      @users[user.name] = user
    end

    # Removes a user from the list.
    # @param [String] user The name of the user we want to delete.
    def remove user
      @users.delete(user.to_s)
    end

    # Removes the user from the list and parts the user from all channels.
    # @param [String] user The name of the user that quit.
    def quit user
      remove(user).part_all
    end

    # Clear the list.
    def clear
      @users.clear
    end

    # Enumerate trough all users on the list.
    # @yield [User] Gives the user to the block.
    def each(&block)
      @users.values.each(&block)
    end

    # Returns the list of users as an array.
    def to_a
      @users.values
    end
  end

end