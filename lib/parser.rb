module Scarlet::Parser
  class << self

    def parse_names_list mode_list, string # parses NAMES list
      modes = mode_list.except(:registered).remap { |k,v| [v[:prefix], v[:symbol]] }
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
    
    def self.parse line_orig
      line = line_orig.dup # just in case, the line gets modified in the method
      prefix = ''
      command = ''
      params = []

      if RUBY_VERSION >= '1.9'
        line.force_encoding('utf-8').encode! 'utf-8', :invalid => :replace, :undef => :replace
        line = line.chars.select(&:valid_encoding?).join
      end

      msg = StringScanner.new(line)
      
      if msg.peek(1) == ':'
        msg.pos += 1
        prefix = msg.scan /\S+/
        msg.skip /\s+/
      end
      
      command = msg.scan /\S+/
      
      until msg.eos?
        msg.skip /\s+/
        
        if msg.peek(1) == ':'
          msg.pos += 1
          params << msg.rest
          msg.terminate
        else
          params << msg.scan(/\S+/)
        end
      end

      target = params.slice!(0)
      
      {:prefix => prefix, :command => command, :target => target, :params => params}
    end
  end
end
