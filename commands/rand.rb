#=========================================#
# // Random
#=========================================#
# // Created by IceDragon (IceDragon200)
#=========================================#
module IrcBot
  module IcyCommands
    # klik - Is a one click stopwatch
    Scarlet.hear /klik/i, :registered do
      n = ::IrcBot::IcyCommands.klik.round(2)
      reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
    end
    def self.klik
      @klik ||= [Time.now,Time.now]
      @klik[0] = Time.now - @klik[1]
      @klik[1] = Time.now
      @klik[0]
    end
    # time - Prints the current owners time
    Scarlet.hear /time/i, :registered do
      reply Time.now.std_format
    end
    # hb <name> - Prints a happy birthday to <name>
    Scarlet.hear /hb (\S+)/i, :registered do
      reply "Happy Birthday #{params[1]}!"
    end
  end
end