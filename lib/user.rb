module Scarlet
  module User
    class << self
      def ns_login? chan_list, nick
        chan_list.any? {|(key,val)| (n = val[:users][nick]) and n[:ns_login] }
      end

      def ns_logout chan_list, nick
        chan_list.each {|key, val| val[:users][nick][:ns_login] = false if val[:users][nick]}
      end

      def ns_login chan_list, nick
        chan_list.each {|key, val| val[:users][nick][:ns_login] = true if val[:users][nick]}
      end
    end
  end
end