class Scarlet
  module NickHelper
    # Tries to escape special nicknames and returns the corrected one
    #
    # @param [String] name
    # @return [String]
    def handle_special_nick(name)
      case name
      when ':me', 'me'
        sender.nick
      when ':you', 'you'
        server.current_nick
      else
        name
      end
    end

    # Splits a string by words and returns the coresponding Nicks
    #
    # @param [String] names
    # @return [Scarlet::Nick]
    def find_nicks(names)
      names.words.map do |name|
        name = handle_special_nick(name)
        Scarlet::Nick.first(nick: name)
      end
    end

    # Returns a Nick for the given nickname
    #
    # @param [String] name
    # @return [Scarlet::Nick]
    def find_nick(name)
      find_nicks(name).first
    end

    # Expects the command to have a :nick param
    #
    # @param [String] nn  nickname to look for, if nil, will expect a params[:nick]
    # @yieldparam [Scarlet::Nick] nick
    def with_nick(nn = nil, &block)
      (options, nn = nn, nn[:nick]) if nn.is_a?(Hash)
      options ||= {}
      options[:msgfmt] ||= 'Cannot find Nick %s'
      nickname = handle_special_nick(nn || params[:nick])
      if nick = Scarlet::Nick.first(nick: nickname)
        catch :skip do
          block.call nick
        end
      else
        reply options.fetch(:msgfmt) % nickname
      end
    end

    # Returns the Nick for the sender
    #
    # @return [Scarlet::Nick]
    def sender_nick
      Scarlet::Nick.first(nick: sender.nick)
    end

    # Checks if 2 given nicks match
    #
    # @param [Scarlet::Nick, String] a
    # @param [Scarlet::Nick, String] b
    # @return [Boolean]
    def same_nick?(a, b)
      a = a.nick if a.is_a?(Scarlet::Nick)
      b = b.nick if b.is_a?(Scarlet::Nick)
      a.downcase == b.downcase
    end
  end
end
