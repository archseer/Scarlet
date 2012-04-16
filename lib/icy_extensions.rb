# // 04/07/2012
# // 04/15/2012
# // Created by IceDragon
# // Version 0.101B
# // Neat function
#=========================================#
# // ● Change Log
#=========================================#
# // ■(04/09/2012)
# //    Commands
# //      memo (changes)
# //        memoF replaced by memo_msg
# //    Functions
# //      get_save_contents()
# //      load_from(contents)
# //
# // ■(04/10/2012)
# //    Commands
# //      poke
# // ■(04/14/2012)
# //    Commands 
# //      memo (changes)
# //        added "REM" parameter
# //        fixed "CLEAR"
# // ■(04/15/2012)
# //    Commands
# //      memo (changes) 1.007
# //        updated help
# //      icver (Added)
# //      poke (changes) 1.001 
# //        Notifies of poke success
# // ■()
#=========================================#
class ::Hash
  def get_values(*args)
    args.collect{|n|self[n]}
  end unless method_defined? :get_values
end
# //
class ::IrcBot::IrcCommands::IcyCommands < ::IrcBot::IrcCommands::Command
  VERSION = "V0.101B"
  class HelpTable
    attr_accessor :colors, :width
    def initialize(width,lines=[])
      @width   = width
      @colors  = {}
      @colors[0] = [1,0] # // Content
      @colors[1] = [0,1] # // Header
      @colors[2] = [1,8] # // Warning
      @lines   = []
      lines.each{|l|add_line(*l)} # // [string, align]
    end
    def clear_lines()
      @lines.clear()
      self
    end
    def add_line(string,color_set=0,align=:left,padding=0)
      @lines << [string,align,padding,color_set]
      self
    end
    def to_a()
      @lines.collect{|a|a[0].align(@width,a[1],a[2]).irc_color(*@colors[a[3]])}
    end
  end
  @@help_table = HelpTable.new(60)
  def self.mauthor
    "IceDragon"
  end
  # // Conv
  def self.p2int(params_a,*ns)
    ns.collect{|n|params_a[n].to_i}
  end
  def self.p2str(params_a,*ns)
    ns.collect{|n|params_a[n].to_s}
  end
  def self.hlpF(str)
    format("[USAGE] %s", str)
  end
  # // Marshalling
  def self.get_save_contents()
    contents = {}
    contents[:memos] = @memos
    contents
  end
  def self.load_from(contents)
    @memos = contents[:memos]
  end
  # // scope - :channel, :return_to_sender, :user
  # // access_level - :any, :registred, :vip, :dev
  def self.new_command(name,scope=:channel,access_level=:user,hlp=[""],arity=0,&method)
    commands_scope(scope)
    access_levels( name => access_level)
    help(          name => hlp         )
    arities(   name => arity       )
    # // author(        name => mauthor     ) # if you ever implement something like that
    on(name,&method)
  end
  # // IcVer 1.000 - IcyCommand Version
  hlp = hlpF "!icver"
  new_command(:icver,:return_to_sender,:dev,hlp,0) do |data|
    ex = ::IrcBot::IrcCommands::IcyCommands
    "IcyCommands #{ex::VERSION} by #{ex.mauthor}"
  end
  # // Dice 1.004
  DICE_LIMIT = 12
  hlp = hlpF "!dice <int sides> [<int dies>]"
  new_command(:dice,:channel,:any,hlp,1..2) do |data|
    params  = data[:params]
    ex      = ::IrcBot::IrcCommands::IcyCommands
    sides, diecoun = ex.p2int(params.split(" "),0,1)
    sides   = 1 if(sides<=0)
    diecoun = 1 if(diecoun<=0)
    dice    = [diecoun,DICE_LIMIT].min.times.collect{|i|1+rand(sides)}
    dice.inject(0){|r,i|r+i}.to_s + " : " + dice.inspect
  end
  # // Coin 1.003
  COIN_LIMIT = 12
  hlp = hlpF "!coin <int count>"
  new_command(:coin,:channel,:any,hlp,1) do |data|
    params = data[:params]
    ex    = ::IrcBot::IrcCommands::IcyCommands
    count,= ex.p2int(params.split(" "),0)
    ([[count,0].max,COIN_LIMIT].min).times.collect{|i|rand(2) == 0 ? "O" : "X"}.inspect.gsub('"',"")
  end
  # // Klik 1.003
  hlp = hlpF "!klik"
  new_command(:klik,:channel,:any,hlp,0) do |data|
    params = data[:params]
    ex = ::IrcBot::IrcCommands::IcyCommands; n = ex.klik.to_i
    format("KLIK! %s %s", n.to_s, (n == 1 ? "sec" : "secs"))
  end
  def self.klik()
    @then_klik ||= Time.now
    @klik = Time.now - @then_klik
    @then_klik = Time.now
    @klik
  end
  # // Poke 1.001
  hlp = hlpF "!poke <string name>"
  new_command(:poke,:user,:registered,hlp,1) do |data|
    user, params = data.get_values(:sender,:params)
    unless(respond_to?(:notice))
      notice user, "Poke Disabled (unabled to complete command)"
    else
      notice params.to_s, "#{user} has poked you"
      notice user, "Poke successful"
    end
    nil
  end
  # // Memo 1.007
  hlp = hlpF "!memo ([about]|[list]|[clear]|[check] <id>|[add] <recipient> <message>|[rem] <id>)"
  new_command(:memo,:user,:registered,hlp,1..3) do |data|
    user, params = data.get_values(:sender,:params)
    ex      = ::IrcBot::IrcCommands::IcyCommands
    sparams = params.split(" ")
    case(sparams[0].upcase)
    when "LIST"
      mems = ex.memos(user)||[] # <<
      ex.memo_msg("LIST",mems)
    when "CHECK"
      mems = ex.memos(user) # <<
      mem  = mems ? mems[sparams[1].to_i] : nil
      ex.memo_msg("CHECK",mem)
    when "ADD"
      ex.add_memo(user, sparams[1], sparams[2...sparams.size].join(" ")) ? ex.memo_msg("ADD") : ex.memo_msg("FADD")
    when "REM"  
      case(ex.remove_memo(user,sparams[1].to_i))
      when 0 # // Invalid nick
        ex.memo_msg("FREM")
      when 1 # // Sucess
        ex.memo_msg("REM")
      when 2 # // No Memo
        ex.memo_msg("NREM")
      end
    when "CLEAR"
      ex.memo_msg("CLEAR",ex.clear_memos(user))
    when "ABOUT"
      "Memo V1.006 by IceDragon".align(40,:center,2).irc_color(1,12)
    else
      "Invalid parameters given.".align(40,:center,2).irc_color(1,5)
    end
  end
  # // Keys are always UPCASED for ease of use I guess
  def self.memos(nick)
    n = ::IrcBot::Nick.where(:nick=>nick).first
    n ? n.memos : nil
  end
  def self.add_memo(sender,recipient,message)
    n = ::IrcBot::Nick.where(:nick=>recipient).first
    if(n)
      n.memos << ::IrcBot::Nick::Memo.new(:sender=>sender, :message=>message)
      n.save!
      true
    else
      false
    end
  end
  def self.remove_memo(nick,id)
    n = ::IrcBot::Nick.where(:nick=>recipient).first
    if(n)
      m = n.memos.delete_at(id)
      n.save!
      m ? 1 : 2
    else
      0
    end  
  end
  def self.clear_memos(recipient)
    n = ::IrcBot::Nick.where(:nick=>recipient.upcase).first
    if(n)
      n.memos.clear
      n.save!
      true
    else
      false
    end
  end
  def self.memo_msg(type,*params)
    param,=params
    case(type)
    when "LIST"
      @@help_table.clear_lines()
      @@help_table.width = 60
      @@help_table.add_line(format("You have %d %s", param.size, param.size == 1 ? "Memo" : "Memos"),1,:center,0)
      param.each_with_index{|m,i|@@help_table.add_line("#{i} "+m.to_short_s,0,:left,2)}
      @@help_table.to_a
    when "ADD"
      "Memo successfully added".align(40,:center,2).irc_color(1,9)
    when "FADD"
      "Memo could not be added".align(40,:center,2).irc_color(1,8)
    when "REM"
      "Memo removed successfully".align(40,:center,2).irc_color(1,9)
    when "NREM"  
      "Memo does not exist".align(40,:center,2).irc_color(1,8)
    when "FREM"
      "Memo could not be removed".align(40,:center,2).irc_color(1,8)
    when "CHECK"
      if(param)
        @@help_table.clear_lines()
        @@help_table.width = 60
        @@help_table.add_line(format("Time: %s", param.created_at),1,:center,0)
        @@help_table.add_line(format("%s: %s", param.sender, param.message),0,:left,0)
        @@help_table.to_a
      else
        "[No Memos]".align(40,:center,2).irc_color(0,1) 
      end
    when "CLEAR"
      (param ? "Memos cleared." : "No Memos to clear.").irc_color(0,1)
    else # // Empty
      "[NO MESSAGE]"
    end
  end
end
#=■==========================================================================■=#
#                           // ● End of File ● //                              #
#=■==========================================================================■=#