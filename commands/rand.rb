#=========================================#
# // Random
#=========================================#
module IrcBot
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
  n = ::IrcBot::IcyCommands.klik.round(2)
  reply format("KLIK! %0.2f %s", n, "sec".pluralize(n))
end
# time - Prints the current owners time
Scarlet.hear /time/i, :registered do
  reply Time.now.std_format
end
# hb <name> - Prints a happy birthday to <name>
Scarlet.hear /hb (\S+)/i, :registered do
  reply "Happy Birthday #{params[1]}!"
end
# rehab (add <string>|clear) - Tasered everytime you say <string>
Scarlet.hear /rehab (add (.*)|clear)/i, :dev do
  case(params[1])
  when /add (.*)/i
    str = params[1]
    if(Watchdog.add_watch(str) { |event| notice event.sender.nick, ["ZAP!!!", "BZZT!!!"].sample })
      notice sender.nick, "#{str} added to rehab list"
    else
      notice sender.nick, "#{str} is already on the rehab list"
    end
  when /clear/i
    Watchdog.clear_watch
    notice sender.nick, "Rehab has been cleared"
  end
end