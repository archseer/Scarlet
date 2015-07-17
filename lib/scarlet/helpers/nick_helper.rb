class Scarlet
  module NickHelper
    def handle_special_nick(name)
      case name
      when ':me'
        sender.nick
      when ':you'
        server.current_nick
      else
        name
      end
    end

    def find_nicks(names)
      names.words.map do |name|
        name = handle_special_nick(name)
        Scarlet::Nick.first(nick: name)
      end
    end

    def find_nick(name)
      find_nicks(name).first
    end

    # Expects the command to have a :nick param
    #
    # @param [String] nn  nickname to look for, if nil, will expect a params[:nick]
    # @yieldparam [Nick] nick
    def with_nick(nn = nil, &block)
      options = {
        msgfmt: 'Cannot find Nick %s'
      }
      if nn.is_a?(Hash)
        options = nn
        nn = options[:nick]
      end
      nickname = handle_special_nick(nn || params[:nick])
      if nick = Scarlet::Nick.first(nick: nickname)
        catch :skip do
          block.call nick
        end
      else
        reply options.fetch(:msgfmt) % nickname
      end
    end

    def sender_nick
      Scarlet::Nick.first(nick: sender.nick)
    end

    def same_nick?(a, b)
      a = a.nick if a.is_a?(Scarlet::Nick)
      b = b.nick if b.is_a?(Scarlet::Nick)
      a.downcase == b.downcase
    end
  end
end
