class HashDowncased < Hash ; end # // Stub
module Scarlet

  module Channels
    # Hash<server_name, Hash<channel_name, channel_hash>>
    @@channels = HashDowncased[]

    class << self

    def clean server_name
      @@channels[server_name].clear
    end

    def mk_hash channel_name
      {
        #name:       channel_name,
        users:      [],
        user_flags: HashDowncased[],
        flags:      []
      }
    end

    def get_server server_name
      @@channels[server_name]
    end

    def get_channel server_name, channel_name
      server = get_server(server_name)
      return nil unless server
      server[channel_name]
    end

    def get *args
      if args.size == 1
        get_server *args
      elsif args.size == 2
        get_channel *args
      else
        nil
      end
    end

    def add_server server_name
      @@channels[server_name] ||= HashDowncased[]
    end

    def add_channel server_name, channel_name
      server = get_server(server_name)
      server[channel_name] ||= mk_hash(channel_name)
    end

    alias [] get

    def remove_channel server_name, channel_name
      server  = get_server(server_name)
      channel = server[channel_name]
      return unless channel
      channel[:users].each do |user_name|
        remove_user_from_channel(server_name, user_name, channel_name)
      end
      server.delete(channel_name)
    end

    def remove_user_from_channel server_name, user_name, channel_name
      server  = get_server(server_name)
      user    = Scarlet::Users[server_name, user_name]
      channel = self[server_name, channel_name]
      return unless user and channel
      channel[:users].delete(user_name)
      user[:channels].delete(channel_name)
      Scarlet::Users.remove_user(server_name, user_name) if user[:channels].empty?
    end

    def add_user_to_channel server_name, user_name, channel_name
      server  = get_server(server_name)
      user    = Scarlet::Users.add_user(server_name, user_name)
      channel = add_channel(server_name, channel_name) 
      channel[:users] << user_name unless channel[:users].include?(user_name)
      user[:channels] << channel_name unless user[:channels].include?(channel_name)
    end

    end

  end

end