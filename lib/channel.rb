require_relative 'collection.rb'

module Scarlet
  # A representation of a channel on the network.
  class Channel
    attr_accessor :topic, :bans, :users, :modes, :user_flags
    attr_reader :name

    # @param [String] name Name of the channel.
    def initialize name
      @name = name
      @users = Users.new
      @user_flags = {}
      @modes = []
      @bans = []
      @topic = nil
    end

    # @param [User] user Remove a user from the channel.
    def remove_user user
      @users.remove user
      @user_flags.delete user
    end
  end

  # Represents a collection of channels.
  class Channels < Collection

  end

  class ServerChannels < Channels
    def remove channel
      @collection.delete(channel).users.each {|user|
        user.part channel
      }
    end

    def remove_channel channel
      @collection.remove channel
    end
  end

end