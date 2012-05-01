module OutputHelper
  def print_chat nick, message, silent=false
    msg = Scarlet::Parser.parse_esc_codes message
    time = "[#{Time.now.strftime("%H:%M")}]"
    if msg =~ /\x01ACTION\s(.+)\x01/ #detect '/me'
      puts "#{time} * #{nick} #{$1}".light_blue if !silent
      @log.info "#{time} * #{nick} #{$1}"
    else
      puts "#{time.light_white} <#{nick.light_red}> #{msg}" if !silent
      @log.info "#{time} <#{nick}> #{Scarlet::Parser.parse_esc_codes message, true}"
    end
  end

  def print_console message, color=nil
    msg = Scarlet::Parser.parse_esc_codes message
    msg = "[#{Time.now.strftime("%H:%M")}] #{msg}"
    puts color ? msg.colorize(color) : msg
    @log.info Scarlet::Parser.parse_esc_codes message, true
  end
end