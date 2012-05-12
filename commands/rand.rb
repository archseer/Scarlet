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
Scarlet.hear /time(?: (\S+))?/i, :registered do
  unless params[1]
    reply Time.now.to_s
  else
    nick = Scarlet::Nick.where(:nick=>params[1]).first
    if nick
      zone_str = nick.settings[:timezone] 
      if zone_str
        #begin
          reply Time.now.in_time_zone(zone_str) 
        #rescue(Exception) => ex
        #  reply "Invalid timezone: %s" % zone_str
        #end
      else
        reply "Your timezone is not set: Use !settings timezone your_timezone_string"
      end
    else
      reply 'Cannot view time for "%s".' % params[1]
    end
  end
end
# hb <name> - Prints a happy birthday to <name>
Scarlet.hear /hb (\S+)/i, :registered do
  reply "Happy Birthday #{params[1]}!"
end