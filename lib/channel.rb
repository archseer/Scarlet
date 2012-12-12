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
      @users.remove user.name
      @user_flags.delete user
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id} name=#{@name}, modes=#{@modes}, bans=#{@bans}, topic=#{@topic}>"
    end
  end

  # Represents a collection of channels.
  class Channels
    def initialize
      @channels = {}
    end

    # Gets the queried channel from the collection.
    # @param [String] channel Name of the channel.
    # @return [Channel, nil] The channel, or nil if no such channel exists.
    def get channel
      @channels[channel.to_s]
    end

    # Adds a channel to the collection.
    # @param [Channel] channel The channel we want to add to the collection.
    def add channel
      @channels[channel.name] = channel
    end

    # Removes a channel from the list.
    # @param [String] channel The channel of the channel we want to delete.
    def remove channel
      if channel.is_a? Channel
        @channels.delete(channel.name)
      else
        @channels.delete(channel)
      end
    end

    # Clear the collection.
    def clear
      @channels.clear
    end

    # Enumerate trough all channels on the list.
    # @yield [Channel] Gives the channel to the block.
    def each(&block)
      @channels.values.each(&block)
    end
  end

  class ServerChannels < Channels
    def remove channel
      if channel.is_a? Channel
        c = @channels.delete(channel.name)
      else
        c = @channels.delete(channel)
      end
      c.users.each {|user|
        user.remove_channel channel
      }
    end

    def remove_channel channel
      @channels.remove channel
    end
  end

end