#=========================================#
# // Date Created : 04/07/2012
# // Date Modified: 04/26/2012
# // Created by IceDragon (IceDragon200)
#=========================================#
# // ● Current Commands in VERSIONS
#=========================================#
module IrcBot
  module IrcCommands::IcyCommands
    VERSIONS = {
      "IC"      => "V0.2000",
      "VERSION" => "V2.0000",
      "DICE"    => "V2.0000",
      "COIN"    => "V2.0000",
      "KLIK"    => "V2.0000",
      "HB"      => "V2.0000",
      "TIME"    => "V2.0000",
      "MEMO"    => "V2.0000"
    }
    def self.mauthor
      "IceDragon"
    end
    Scarlet.hear /version (.*)/i do
      ver = IrcBot::IrcCommmands::IcyCommands::VERSIONS[params[0].upcase]
      ver ? "Version #{ver}" : "unknown #{params[0]}"
    end
    Scarlet.hear /dice (\d+)d(\d+)/i do
      sides, diecoun = params[0].to_i, params[1].to_i
      sides   = 1 if(sides<=0)
      diecoun = 1 if(diecoun<=0)
      dice    = diecoun.times.collect{|i|1+rand(sides)}
      reply format("%d : %s", dice.inject(0){|r,i|r+i}, dice.inspect)
    end
    Scarlet.hear /coin (\d+)/i do
      count, = params[0].to_i
      reply count.times.collect{|i|rand(2) == 0 ? "O" : "X"}.inspect.gsub('"',"")
    end
    VERSIONS["KLIK"] = "2.0000"
    Scarlet.hear /klik/i do
      n = ::IrcBot::IrcCommands::IcyCommands.klik.round(2)
      reply format("KLIK! %0.2f %s", n, (n == 1 ? "sec" : "secs"))
    end
    def self.klik()
      @then_klik ||= Time.now
      @klik        = Time.now - @then_klik
      @then_klik   = Time.now
      @klik
    end
    VERSIONS["TIME"]= "2.0000"
    Scarlet.hear /time/i do
      Time.now
    end
    VERSIONS["HB"]= "2.0000"
    Scarlet.hear /hb (\S+)/i
      reply format("Happy Birthday %s!", params[0])
    end
    memo_size,memo_padd = 40, 2
    MEMO_MSG = {
      "ADD"   => "Memo successfully added".align(memo_size,:center,memo_padd).irc_color(1,9),
      "FADD"  => "Memo could not be added".align(memo_size,:center,memo_padd).irc_color(1,8),
      "REM"   => "Memo removed successfully".align(memo_size,:center,memo_padd).irc_color(1,9),
      "NREM"  => "Memo does not exist".align(memo_size,:center,memo_padd).irc_color(1,8),
      "FREM"  => "Memo could not be removed".align(memo_size,:center,memo_padd).irc_color(1,8),
      "ABOUT" => "Memo V1.006 by IceDragon".align(memo_size,:center,memo_padd).irc_color(1,12),
      "NOMEMO"=> "No memos avaiable".align(memo_size,:center,memo_padd).irc_color(0,1),
      "CLEAR" => "All memos have been cleared.".align(memo_size,:center,memo_padd).irc_color(0,1),
      "NCLEAR"=> "There are no memos to clear.".align(memo_size,:center,memo_padd).irc_color(0,5),
      "INVAL" => "Invalid parameters given.".align(memo_size,:center,memo_padd).irc_color(1,5)
    }
    MEMO_MSG.default("[NO MESSAGE]")
    # '!memo ([about]|[list]|[clear]|[check] <id>|[add] <recipient> <message>|[rem] <id>)'
    Scarlet.hear /memo (about|list|clear|check (\d+)|add (\S+) (.+)|rem (\d+))/i do
      ex = ::IrcBot::IrcCommands::IcyCommands
      case(params[0])
      when /LIST/i
        ex.memo_msg("LIST",(ex.memos(user)||[]))
      when /CHECK (\d+)/i
        mems = ex.memos(user)
        mem  = mems ? mems[params[1].to_i] : nil
        ex.memo_msg("CHECK",mem)
      when /ADD (\S+) (.+)/i
        ex.add_memo(user, params[1], params[2...params.size].join(" ")) ? ex.memo_msg("ADD") : ex.memo_msg("FADD")
      when /REM (\d+)/i
        case(ex.remove_memo(user,params[1].to_i))
        when 0 ; ex.memo_msg("FREM") # // Invalid nick
        when 1 ; ex.memo_msg("REM")  # // Sucess
        when 2 ; ex.memo_msg("NREM") # // No Memo
        end
      when "CLEAR" ; ex.memo_msg("CLEAR",ex.clear_memos(user))
      when "ABOUT" ; ex.memo_msg("ABOUT")
      else         ; ex.memo_msg("INVAL")
      end
    end
    def self.memos(nick)
      n = ::IrcBot::Nick.where(:nick=>nick).first
      n ? n.memos : nil
    end
    def self.add_memo(sender,recipient,message)
      n = ::IrcBot::Nick.where(:nick=>recipient).first
      return false unless(n)
      n.memos << ::IrcBot::Nick::Memo.new(:sender=>sender, :message=>message)
      !!n.save!
    end
    def self.remove_memo(nick,id)
      n = ::IrcBot::Nick.where(:nick=>recipient).first
      return 0 unless(n)
      m = n.memos.delete_at(id)
      n.save!
      m ? 1 : 2
    end
    def self.clear_memos(recipient)
      n = ::IrcBot::Nick.where(:nick=>recipient.upcase).first
      return false unless(n)
      n.memos.clear
      !!n.save!
    end
    def self.memo_msg(type,*params)
      param,=params
      case(type)
      when "LIST"
        @@help_table.clear
        @@help_table.width = 60
        @@help_table.addHeader("You have %d %s" % [param.size, param.size == 1 ? "memo" : "memos"])
        param.each_with_index{|m,i|@@help_table.addRow("#{i} %s" % m.to_short_s)}
        @@help_table.compile
      when "CHECK"
        return MEMO_MSG["NOMEMO"] unless(param)
        @@help_table.clear
        @@help_table.width = 60
        @@help_table.addHeader "Time: %s" % param.created_at 
        @@help_table.addRow "%s: %s" % [param.sender, param.message]
        @@help_table.compile
      else # // Empty
        MEMO_MSG[type]
      end
    end
  end
end
#=■==========================================================================■=#
#                           // ● End of File ● //                              #
#=■==========================================================================■=#