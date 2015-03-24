module Scarlet
  module Fmt
    # Formats a given uri suitable for the irc
    def self.uri(u)
      # Speed said that his irc client picks up ( ) as a apart of the uri, so adding some spaces
      # shouldn't hurt.
      "( #{u} )"
    end

    # Formats a Github sha value
    def self.commit_sha(sha)
      sha[0, 8].center(10, ' ').irc_color(1, 8)
    end
  end
end
