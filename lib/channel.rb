module Scarlet

  module Channel
    @@channels = HashDowncased[]
  end

  class << Channel

    def mk_channel_hash channel
      {
        name:       channel,
        users:      Set[],#HashDowncased[],
        user_flags: HashDowncased[],
        flags:      []
      }
    end

    def has_channel? channel_name
      @channels[channel_name]
    end

    def add_channel channel_name
      @channels[channel_name] ||= mk_channel_hash(channel_name)
    end

    def remove_channel channel_name
      channel = has_channel?(channel_name)
      return unless channel
      channel[:users].each_key do |user_name|
        remove_user_from_channel(user_name, channel_name)
      end
      @channels.delete(channel_name)
    end

  end

end