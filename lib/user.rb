module Scarlet
  module User
    class << self
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
    end
  end
end