#=========================================#
# // IcyCommands (main)
#=========================================#
module IrcBot
  module IcyCommands
    VERSIONS = {
      "IC"      => "V0.2000",
      "VERSION" => "V2.0000",
      "DICE"    => "V2.0000",
      "COIN"    => "V2.0000",
      "KLIK"    => "V2.0000",
      "HB"      => "V2.0000",
      "TIME"    => "V2.0001",
      "WIN"     => "V2.0000",
      "MEMO"    => "V2.0001"
    }
    def self.mauthor
      "IceDragon"
    end
  end
end
# version <name> - Shows the version number of <name> command (Only supports ICY comamnds)
Scarlet.hear /version (\S+)/i, :any do
  ver = IrcBot::IcyCommands::VERSIONS[params[1].upcase]
  reply ver ? "Version #{ver}" : "unknown #{params[1]}"
end
# win <name> - Show some respect to <name>, and give em a win point
Scarlet.hear /win[ ]*(\S*)/i, :registered do
  n = ::IrcBot::Nick.where(:nick=> params[1]).first
  if(n)
    n.win_points += 1
    n.save!
    notice sender.nick, "You gave #{sender.nick} a win!" 
  else
    wins = ::IrcBot::Nick.where(:nick=> sender.nick).first.win_points
    notice sender.nick, "You have #{wins} #{"win point".pluralize.(n.wins)}" 
  end
end
#=■==========================================================================■=#
#                           // ● End of File ● //                              #
#=■==========================================================================■=#