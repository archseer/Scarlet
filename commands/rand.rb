#=========================================#
# // Random
#=========================================#
module Scarlet
  module IcyCommands
    def self.klik
      @klik ||= [Time.now,Time.now]
      @klik[0] = Time.now - @klik[1]
      @klik[1] = Time.now
      @klik[0]
    end
  end
end
# klik - Is a one click stopwatch
Scarlet.hear /klik/i, :registered do
  n = Scarlet::IcyCommands.klik.round(2)
  reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
end
# time - Prints the current owners time
Scarlet.hear /time( \d+)?/i, :registered do
  reply Time.now.std_format
end
# hb <name> - Prints a happy birthday to <name>
Scarlet.hear /hb (\S+)/i, :registered do
  reply "Happy Birthday #{params[1]}!"
end