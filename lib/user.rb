module ::IrcBot::User
  class << self
    def ns_login? chan_list, nick
      ns_login = false
      chan_list.each {|key, val| 
        ns_login = true if val[:users][nick][:ns_login]
      } #it will get set to true if at least one chan detects login. hax
      return ns_login
    end

    def ns_logout chan_list, nick
      chan_list.each {|key, val| ns_login = val[:users][nick][:ns_login] = false}
    end

    def ns_login chan_list, nick
      chan_list.each {|key, val| ns_login = val[:users][nick][:ns_login] = true}
    end
  end
end