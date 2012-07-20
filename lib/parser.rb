module Scarlet::Parser
  class << self

    def convert_prfx_to_sym server, array
      modes = server.mode_list.remap { |k,v| [v[:prefix],v[:name].to_sym] }
      array.collect do |c| modes[c] || c end
    end

    def convert_to_mode_prefixes server, hash
      active_syms = hash.select do |(k,v)| v end.map(&:first)
      mlist = server.mode_list
      active_syms.map do |s| mlist[s][:prefix] end
    end

    def parse_names_list server, string # parses NAMES list
      settings = {}
      mlist = server.mode_list.dup
      mlist.delete :registered
      modes = mlist.remap{ |k,v| [v[:symbol], v[:prefix]] }
      #{'~' => :owner, '&' => :admin, '@' => :operator, '%' => :halfop, '+'=> :voice}
      matdata = string.match /([\+%@&~]*)(\S+)/
      umodes, name = matdata[1].split(""), matdata[2]
      modes.values.each{ |v| settings[v] = false }
      umodes.each { |k| settings[modes[k]] = true }
      settings = settings.inject([]) do |a,(k,v)| 
        a << k if v unless a.include?(k) ; a 
      end
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

    # // Using a C styled approach (Pointer mode_array),
    def parse_modes new_modes, mode_array, mode=true
      new_modes.each do |c|
        mode = (c=="+") ? true : (c == "-" ? false : mode)
        next if c == "+" or c == "-" or c == " "
        mode ? mode_array << c : mode_array.subtract_once(c)
      end
    end
    
  end
end
