#=========================================#
# // Memo
#=========================================#
# // Created by IceDragon (IceDragon200)
#=========================================#
module IrcBot
  module IcyCommands
    # // Memo :3
    memo_size,memo_padd = 40, 2
    MEMO_MSG = {
      "ADD"   => "Memo successfully added".align(memo_size,:center,memo_padd).irc_color(1,9),
      "FADD"  => "Memo could not be added".align(memo_size,:center,memo_padd).irc_color(1,8),
      "REM"   => "Memo removed successfully".align(memo_size,:center,memo_padd).irc_color(1,9),
      "NREM"  => "Memo does not exist".align(memo_size,:center,memo_padd).irc_color(1,8),
      "FREM"  => "Memo could not be removed".align(memo_size,:center,memo_padd).irc_color(1,8),
      "ABOUT" => "Memo V1.006 by IceDragon".align(memo_size,:center,memo_padd).irc_color(1,12),
      "NOMEMO"=> "Memos are not available".align(memo_size,:center,memo_padd).irc_color(0,1),
      "CLEAR" => "Memos have been cleared".align(memo_size,:center,memo_padd).irc_color(0,1),
      "NCLEAR"=> "Memos are empty".align(memo_size,:center,memo_padd).irc_color(0,5),
      "INVAL" => "Invalid parameters given".align(memo_size,:center,memo_padd).irc_color(1,5)
    }
    MEMO_MSG.default("[NO MESSAGE]")
    # memo ([about]|[list]|[clear]|[check] <id>|[add] <recipient> <message>|[rem] <id>) - Memo, so much going on its hard to explain
    Scarlet.hear /memo (about|list|clear|check (\d+)|add (\S+) (.+)|rem (\d+))/i, :registered do
      ex = ::Scarlet::IrcCommands::IcyCommands
      reply case(params[0])
      when /LIST/i
        ex.memo_msg("LIST",(ex.memos(sender.nick)||[]))
      when /CHECK (\d+)/i
        mems = ex.memos(sender.nick)
        mem  = mems ? mems[params[1].to_i] : nil
        ex.memo_msg("CHECK",mem)
      when /ADD (\S+) (.+)/i
        ex.add_memo(sender.nick, params[1], params[2...params.size].join(" ")) ? ex.memo_msg("ADD") : ex.memo_msg("FADD")
      when /REM (\d+)/i
        case(ex.remove_memo(sender.nick,params[1].to_i))
        when 0 ; ex.memo_msg("FREM") # // Invalid nick
        when 1 ; ex.memo_msg("REM")  # // Sucess
        when 2 ; ex.memo_msg("NREM") # // No Memo
        end
      when "CLEAR" ; ex.memo_msg("CLEAR",ex.clear_memos(sender.nick))
      when "ABOUT" ; ex.memo_msg("ABOUT")
      else         ; ex.memo_msg("INVAL")
      end
    end
    def self.memos(nick)
      n = Nick.where(:nick=>nick).first
      n ? n.memos : nil
    end
    def self.add_memo(sender,recipient,message)
      n = Scarlet::Nick.where(:nick=>recipient).first
      return false unless(n)
      n.memos << Scarlet::Nick::Memo.new(:sender=>sender, :message=>message)
      !!n.save!
    end
    def self.remove_memo(nick,id)
      n = Scarlet::Nick.where(:nick=>recipient).first
      return 0 unless(n)
      m = n.memos.delete_at(id)
      n.save!
      m ? 1 : 2
    end
    def self.clear_memos(recipient)
      n = Scarlet::Nick.where(:nick=>recipient.upcase).first
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