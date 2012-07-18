# for outputting and logging messages
module Kernel

  def print_chat nick, message, silent=false
    msg = Scarlet::Parser.parse_esc_codes message
    time = "[#{Time.now.strftime("%H:%M")}]"
    if msg =~ /\x01ACTION\s(.+)\x01/ #detect '/me'
      puts "#{time} * #{nick} #{$1}".light_blue if !silent
    else
      puts "#{time.light_white} <#{nick.light_red}> #{msg}" if !silent
    end
  end

  def print_console message, color=nil
    msg = Scarlet::Parser.parse_esc_codes message
    time = "[#{Time.now.strftime("%H:%M")}]"
    msg = "#{time} #{msg}"
    puts color ? msg.colorize(color) : msg
  end

end