# // Similar to Scarlet
module Watchdog
  class << self
    @@watching = {}
    @@rest = false
    def check_event(event)
      return if(resting?)
      str = event.params.first
      @@watching.keys.each_pair { |key,blck| blck.call(event) if(str.include?(key)) }
    end
    def resting?
      @@rest
    end
    def toggle_rest
      @@rest = !@@rest
    end
    def add_watch(str,&block)
      return false if(@@watching.has_key?(str))
      !!(@@watching[str] = block)
    end
    def clear_watch
      @@watching.clear
    end
    def rem_watch(str)
      @@watching.delete(str)
    end
    def mk_nick_table
      Hash[::IrcBot::Nick.all.collect{|n|[n.nick,n.aliases]}.inject({}){|r,a|
        nick, aliases = a
        aliases.each { |s| r[s] = nick };r[nick] = nick
        r
      }.collect{|(k,v)|[k.downcase,v]}]
    end
    def nick_table
      @nick_table ||= mk_nick_table
    end
    def alias2nick(ali)
      nick_table[ali.downcase]
    end
  end
end