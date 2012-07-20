class HashDowncased < Hash ; end # // Stub
module Scarlet

  module Users
    # Hash<server_name, Hash<user_name, user_hash>>
    @@users = HashDowncased[]
  
    class << self

    def clean server_name
      @@users[server_name].clear
    end

    def ns_login? server_name, nick
      server = get_server(server_name)
      user = server[nick]
      user ? user[:ns_login] : false
    end

    def ns_logout server_name, nick
      server = get_server(server_name)
      server[nick][:ns_login] = false if server[nick]
    end

    def ns_login server_name, nick
      server = get_server(server_name)
      server[nick][:ns_login] = true if server[nick]
    end

    def mk_hash nick
      {
        nick:         nick,
        ns_login:     false,
        channels:     []
      }
    end

    def rename_user server_name, old_name, new_name
      return if old_name == new_name
      user = self[server_name, old_name]
      return unless user
      map = {old_name => new_name}
      user[:channels].each do |channel_name|
        channel_hash = Scarlet::Channels[server_name, channel_name]
        channel_hash[:users].map! do |s| s == old_name ? new_name : s end
      end
      get_server(server_name).replace_key!(map)
    end

    def get_server server_name
      @@users[server_name]
    end

    def get_user server_name, user_name
      server = get_server(server_name)
      return nil unless server
      server[user_name]
    end

    def get *args
      if args.size == 1
        get_server *args
      elsif args.size == 2
        get_user *args
      else
        nil
      end
    end

    def add_server server_name
      @@users[server_name] ||= HashDowncased[]
    end

    def add_user server_name, user_name
      server = get_server(server_name)
      server[user_name] ||= mk_hash(user_name)
    end

    alias [] get

    def remove_user server_name, user_name
      server = get_server(server_name)
      user   = server[user_name]
      return unless user
      user[:channels].each do |channel_name|
        Scarlet::Channels.remove_user_from_channel(user_name, channel_name)
      end
      server.delete(user_name)
    end

    end # // << self
  end

end