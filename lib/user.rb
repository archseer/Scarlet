module Scarlet

  module User
    @@users = {}
  end

  class << User  

    def ns_login? server, nick
      user = server.users[nick]
      user ? user[:ns_login] : false
    end

    def ns_logout server, nick
      server.users[nick][:ns_login] = false if server.has_user?(nick)
    end

    def ns_login server, nick
      server.users[nick][:ns_login] = true if server.has_user?(nick)
    end

    def mk_hash nick
      {
        nick:         nick,
        account_name: nil,
        ns_login:     false,
        channels:     Set[],#HashDowncased[],
        flags:        []
      }
    end

    def rename_user old_name,new_name
      return if old_name == new_name
      user = has_user?(old_name)
      return unless user
      map = {old_name => new_name}
      user[:channels].each_value do |channel_hash|
        channel_hash[:users].replace_key!(map)
      end
      @users.replace_key!(map)
    end

    def has_user? user_name
      @users[user_name]
    end

    def add_user user_name
      @users[user_name] ||= mk_user_hash(user_name)
    end

    def remove_user user_name
      user = has_user?(user_name)
      return unless user
      user[:channels].each_key do |channel_name|
        remove_user_from_channel(user_name, channel_name)
      end
      @users.delete(user_name)
    end

    def remove_user_from_channel user_name,channel_name
      user    = has_user?(user_name)
      channel = has_channel?(channel_name)
      return unless user and channel
      channel[:users].delete(user_name)
      user[:channels].delete(channel_name)
    end

    def add_user_to_channel user_name,channel_name
      user    = add_user(user_name) 
      channel = add_channel(channel_name) 
      channel[:users] << user_name #[user_name] = user#_name 
      user[:channels] << channel_name #[channel_name] = channel#_name
    end

  end

end