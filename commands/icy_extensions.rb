#=========================================#
# // Date Created : 04/07/2012
# // Date Modified: 04/25/2012
# // Created by IceDragon (IceDragon200)
#=========================================#
# // ● Current Commands
#=========================================#
# // icver, klik, dice, coin, memo
#=========================================#
# // Added functions
class ::Hash
  def get_values(*args)
    args.collect{|n|self[n]}
  end unless method_defined? :get_values
end
# // Commands
class ::IrcBot::IrcCommands::IcyCommands < ::IrcBot::IrcCommands::Command
  VERSION = "V0.1020"
  @@help_table = ::IrcBot::InfoTable.new(60)
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
  # // scope - :channel, :return_to_sender, :user
  # // access_level - :any, :registred, :vip, :dev
  def self.new_command(name,scope=:channel,access_level=:user,hlp=[""],arity=0,&method)
    commands_scope(scope)
    access_levels( name => access_level)
    help(          name => hlp         )
    arities(       name => arity       )
    on(name,&method)
  end
  # // IcVer 1.001 - IcyCommand Version
  hlp = hlpF "!icver"
  new_command(:icver,:return_to_sender,:dev,hlp,0) do |data|
    ex = ::IrcBot::IrcCommands::IcyCommands
    format("IcyCommands %s by %s", ex::VERSION, ex.mauthor)
  end 
  # // Dice 1.005
  DICE_LIMIT = 12
  hlp = hlpF "!dice <int sides> [<int dies>]"
  new_command(:dice,:return_to_sender,:any,hlp,1..2) do |data|
    params  = data[:params]
    ex      = ::IrcBot::IrcCommands::IcyCommands
    sides, diecoun = ex.p2int(params.split(" "),0,1)
    sides   = 1 if(sides<=0)
    diecoun = 1 if(diecoun<=0)
    dice    = [diecoun,DICE_LIMIT].min.times.collect{|i|1+rand(sides)}
    (dice.inject(0){|r,i|r+i}.to_s + " : " + dice.inspect).to_s
  end
  # // Coin 1.004
  COIN_LIMIT = 12
  hlp = hlpF '!coin <int count>'
  new_command(:coin,:return_to_sender,:any,hlp,1) do |data|
    params = data[:params]
    ex     = ::IrcBot::IrcCommands::IcyCommands
    count, = ex.p2int(params.split(" "),0)
    ([[count,0].max,COIN_LIMIT].min).times.collect{|i|rand(2) == 0 ? "O" : "X"}.inspect.gsub('"',"")
  end
  # // Klik 1.004
  hlp = hlpF '!klik'
  new_command(:klik,:return_to_sender,:any,hlp,0) do |data|
    params = data[:params]
    ex     = ::IrcBot::IrcCommands::IcyCommands; n = ex.klik.to_i
    format("KLIK! %s %s", n.to_s, (n == 1 ? "sec" : "secs"))
  end
  def self.klik()
    @then_klik ||= Time.now
    @klik        = Time.now - @then_klik
    @then_klik   = Time.now
    @klik
  end
  # // Memo 1.009
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
  hlp = hlpF '!memo ([about]|[list]|[clear]|[check] <id>|[add] <recipient> <message>|[rem] <id>)'
  new_command(:memo,:user,:registered,hlp,1..3) do |data|
    ex           = ::IrcBot::IrcCommands::IcyCommands
    user, params = data.get_values(:sender,:params)
    sparams      = params.split(" ")
    case(sparams[0].upcase)
    when "LIST"
      ex.memo_msg("LIST",(ex.memos(user)||[]))
    when "CHECK"
      mems = ex.memos(user)
      mem  = mems ? mems[sparams[1].to_i] : nil
      ex.memo_msg("CHECK",mem)
    when "ADD"
      ex.add_memo(user, sparams[1], sparams[2...sparams.size].join(" ")) ? ex.memo_msg("ADD") : ex.memo_msg("FADD")
    when "REM"
      case(ex.remove_memo(user,sparams[1].to_i))
      when 0 ; ex.memo_msg("FREM") # // Invalid nick
      when 1 ; ex.memo_msg("REM")  # // Sucess
      when 2 ; ex.memo_msg("NREM") # // No Memo
      end
    when "CLEAR" ; ex.memo_msg("CLEAR",ex.clear_memos(user))
    when "ABOUT" ; ex.memo_msg("ABOUT")
    else         ; ex.memo_msg("INVAL")
    end
  end
  # // Keys are always UPCASED for ease of use I guess
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
      @@help_table.clear()
      @@help_table.width = 60
      @@help_table.addHeader(format("You have %d %s", param.size, param.size == 1 ? "memo" : "memos"))
      param.each_with_index{|m,i|@@help_table.addRow("#{i} "+m.to_short_s)}
      @@help_table.compile()
    when "CHECK"
      return MEMO_MSG["NOMEMO"] unless(param)
      @@help_table.clear()
      @@help_table.width = 60
      @@help_table.addHeader(format("Time: %s", param.created_at))
      @@help_table.addRow(format("%s: %s", param.sender, param.message))
      @@help_table.compile()
    else # // Empty
      MEMO_MSG[type]
    end
  end
end
#=■==========================================================================■=#
#                           // ● End of File ● //                              #
#=■==========================================================================■=#