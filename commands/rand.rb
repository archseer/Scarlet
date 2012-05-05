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
Scarlet.hear /time (\S+)?/i, :registered do
  unless params[1]
    reply Time.now
  else
    nick = Scarlet::Nick.where(:nick=>params[1]).first
    if nick
      offset = nick.settings[:timeoffset] || 0
      reply Time.at(Time.now.gmtime + offset.hour).to_s
    else
      reply "Cannot view time for \"#{params[1]}\"."
    end
  end
end
# hb <name> - Prints a happy birthday to <name>
Scarlet.hear /hb (\S+)/i, :registered do
  reply "Happy Birthday #{params[1]}!"
end