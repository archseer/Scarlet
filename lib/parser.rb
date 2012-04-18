module IrcBot::Parser
  class << self

    def parse_names_list string # parses NAMES list
      settings = {}
      modes = $config.irc_bot.modes
      matdata = string.match(/([\+%@&~]*)(\S+)/)
      umodes, name = matdata[1].split(""), matdata[2]
      modes.values.each{|v|settings[v]=false}
      umodes.each {|k|settings[modes[k]]=true}
      return name, settings
    end

    def parse_esc_codes msg, remove=false # parses IRC escape codes into ANSI or removes them.
      new_msg = msg.gsub(/\x02(.+?)\x02/) {
        remove ?  "#{$1}" : "\x1b[1m#{$1}\x1b[22m"
      }
      new_msg = new_msg.gsub(/\x1F(.+?)\x1F/) {
        remove ?  "#{$1}" : "\x1b[4m#{$1}\x1b[24m"
      }
      new_msg
    end

  end
end