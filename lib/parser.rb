module IrcBot::Parser
  class << self

    def extentions_parse data #parses 005 extensions messages
      segments = data.gsub(" :are supported by this server", "").split(" ")
      tree = segments.inject({}) { |hash, segment|
        if s = segment.match(/(?<token>.+)\=(?<parameters>.+)/)
          params = s[:parameters].match(/^[[:digit:]]+$/) ? s[:parameters].to_i : s[:parameters] #convert digit only to digits
          hash[s[:token].downcase.to_sym] = params
        else
          hash[segment.downcase.to_sym] = true
        end
        hash
      }
      return tree
    end

    def parse_names_list string # parses NAMES list
      settings = {}
      modes = $config.irc_bot.modes
      matdata = string.match(/([\+%@&~]*)(\S+)/)
      umodes, name = matdata[1].split(""), matdata[2]
      modes.values.each{|v|settings[v]=false}
      umodes.each {|k|settings[modes[k]]=true}
      return name, settings
    end

    def parse_mode str, users, chan_flags # parses the MODE response (<flags> <user> <user>...)
      chan_flags = [] if !chan_flags
      mode = true
      if h = str.match(/(?<flags>\S+)\s(?<nicklist>.+)/) #means we have an user list
        flags = {"q" => :owner, "a" => :admin, "o" => :operator, "h" => :halfop, "v" => :voice, "r" => :registered}
        operator_count = 0
        nicks = h[:nicklist].split(" ")

        h[:flags].split("").each_with_index do |flag, i|
          mode = (flag=="+") ? true : (flag == "-" ? false : mode)
          operator_count += 1 and next if flag == "+" or flag == "-" 
          next if flag == " "
          nick = nicks[i-operator_count]
          nick[0] != "#" ? users[nick][flags[flag]] = mode : (mode ? chan_flags << c : chan_flags.subtract_once(c)) #chan processing is TEMP embedded.
        end
        
      else #means we split and parse the changes to the channel array for now
        str.split("").each do |c|
          mode = (c=="+") ? true : (c == "-" ? false : mode)
          next if c == "+" or c == "-" or c == " "
          mode ? chan_flags << c : chan_flags.subtract_once(c)
        end
      end
      return users, chan_flags
    end

    def parse_serv_mode str, modes #merge with above
      modes = [] if !modes
      mode = true
      str.split("").each do |c|
        mode = (c=="+") ? true : (c == "-" ? false : mode)
        next if c == "+" or c == "-" or c == " "
        mode ? modes << c : modes.subtract_once(c)
      end
      return modes
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