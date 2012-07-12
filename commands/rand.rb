module Scarlet
  def self.klik
    @klik ||= [Time.now,Time.now]
    @klik[0] = Time.now - @klik[1]
    @klik[1] = Time.now
    @klik[0]
  end
end
# klik - Is a one click stopwatch
Scarlet.hear /klik/i, :registered do
  n = Scarlet.klik.round(2)
  reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
end
# time - Prints the current owners time
Scarlet.hear /time(?: (\S+))?/i, :registered do
  unless params[1]
    reply Time.now.to_s
  else
    nck = params[1].gsub(/-me/i,sender.nick)
    nick = Scarlet::Nick.where(:nick => nck).first
    if nick
      zone_str = nick.settings[:timezone] 
      if zone_str
        reply Time.now.in_time_zone(zone_str).to_s
      else
        reply "Your timezone is not set: Use !settings timezone your_timezone_string"
      end
    else
      reply 'Cannot view time for "%s".' % params[1]
    end
  end
end

# update <name>? - Just to nag the crap out of Speed
Scarlet.hear /update(?: (\S+))?/i, :registered do
  notice params[1]||"Speed", "%s demandes que tu mettre à jour moi!" % sender.nick
  notice sender.nick, "Notice sent."
end