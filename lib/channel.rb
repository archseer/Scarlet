module Scarlet
  class Channel
    attr_accessor :topic, :bans, :users, :modes, :user_flags
    attr_reader :name

    def initialize name
      @name = name
      @users = Users.new
      @user_flags = {}
      @modes = []
      @bans = []
      @topic = nil
    end

    def remove_user user
      @users.remove user.name
      @user_flags.delete user
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id} name=#{@name}, modes=#{@modes}, bans=#{@bans}, topic=#{@topic}>"
    end
  end

  class Channels
    def initialize
      @channels = {}
    end

    def get channel
      @channels[channel.to_s]
    end

    def add channel
      @channels[channel.name] = channel
    end

    def remove channel
      if channel.is_a? Channel
        @channels.delete(channel.name)
      else
        @channels.delete(channel)
      end
    end

    def clear
      @channels.clear
    end

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