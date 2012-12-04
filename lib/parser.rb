module Scarlet::Parser
  class << self

    def convert_prfx_to_sym mode_list, array
      modes = mode_list.remap { |k,v| [v[:prefix],v[:name].to_sym] }
      array.collect do |c| modes[c] || c end
    end

    def convert_to_mode_prefixes mode_list, hash
      active_syms = hash.select { |(k,v)| v }.map(&:first)
      active_syms.map { |s| mode_list[s][:prefix] }
    end

    def parse_names_list mode_list, string # parses NAMES list
      modes = mode_list.except(:registered).remap{ |k,v| [v[:prefix], v[:symbol]] }
      #{:owner => '~', :admin => '&', :operator => '@', :halfop => '%', :voice => '+'}
      params = string.match /(?<prefix>[\+%@&~]*)(?<nick>\S+)/
      modes.each {|key, val| modes[key] = params[:prefix].include?(val)}
      return params[:nick], modes
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
        if mode
          mode_array << c unless mode_array.include?(c)
        else
          mode_array.subtract_once(c)
        end
      end
    end
    
  end
end
