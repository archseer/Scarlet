require 'scarlet/collection'

module Scarlet
  # A representation of a user on the network.
  class User
    attr_accessor :name, :ns_login, :channels, :account_name
    alias :nick :name

    # @param [String] name The name of the user.
    def initialize(name)
      @name = name
      @ns_login = false
      @account_name = nil
      @channels = Channels.new
    end

    # Add the user to a channel.
    # @param [Channel] channel The channel we want to join.
    def join(channel)
      return if @channels.exist? channel.name
      @channels.add channel
      channel.user_flags[self] = {}
      channel.users.add self
    end

    # Remove the user from a channel.
    # @param [Channel] channel The channel we want to part.
    def part(channel)
      @channels.remove(channel)
      channel.user_flags.delete self
      channel.users.remove self
    end

    # Remove the user from all channels.
    def part_all
      @channels.each { |channel| channel.remove_user self }
      @channels.clear
    end
  end

  # Represents a list we use as a storage for a collection of users.
  class Users < Collection
    # Gets an user if he exists, else it creates one.
    # @param [String] user The user we are looking for.
    def get_ensured user
      if exist? user
        get user
      else
        add User.new(user)
      end
    end
  end
end
