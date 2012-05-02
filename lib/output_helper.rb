module OutputHelper
  def print_chat nick, message, silent=false, log_name=:connection
    msg = Scarlet::Parser.parse_esc_codes message
    time = "[#{Time.now.strftime("%H:%M")}]"
    if msg =~ /\x01ACTION\s(.+)\x01/ #detect '/me'
      puts "#{time} * #{nick} #{$1}".light_blue if !silent
      @log.log log_name, "#{time} * #{nick} #{$1}"
    else
      puts "#{time.light_white} <#{nick.light_red}> #{msg}" if !silent
      @log.log log_name, "#{time} <#{nick}> #{Scarlet::Parser.parse_esc_codes message, true}"
    end
  end

  def print_console message, color=nil, log_name=:connection
    msg = Scarlet::Parser.parse_esc_codes message
    time = "[#{Time.now.strftime("%H:%M")}]"
    msg = "#{time} #{msg}"
    puts color ? msg.colorize(color) : msg
    @log.log log_name, "#{time} #{Scarlet::Parser.parse_esc_codes message, true}"
  end
end