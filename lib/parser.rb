class Scarlet::Parser
  @@base_mode_list = {
    :owner      => {:name=>'owner'     ,:prefix=>'q',:symbol=>'~'},
    :admin      => {:name=>'admin'     ,:prefix=>'a',:symbol=>'&'},
    :op         => {:name=>'operator'  ,:prefix=>'o',:symbol=>'@'},
    :hop        => {:name=>'halfop'    ,:prefix=>'h',:symbol=>'%'},
    :voice      => {:name=>'voice'     ,:prefix=>'v',:symbol=>'+'},
    :registered => {:name=>'registered',:prefix=>'r',:symbol=>'' }
  }

  def initialize prefix_list
    # map @mode_list to the list of modes available on the network.

    name_lookup = @@base_mode_list.remap{ |k,v| [v[:prefix], k] }
    #prefix_list.match(/\((?<prefix>\w+)\)(?<symbol>.+)/) {|matches|
    #  Hash[matches[:prefix].split("").zip(matches[:symbol].split(""))]
    #}
    # TODO: use the symbol that's in the prefix_list for the prefix's symbol.

    parsed = prefix_list.match(/\((?<prefix>\w+)\)(?<symbol>.+)/)

    prefixes = parsed[:prefix].split("").each_with_object([]) {|prefix, array| array << name_lookup[prefix] }

    @mode_list = @@base_mode_list.slice(*prefixes)
  end

  def parse_names_list string # parses NAMES list
    modes = @mode_list.except(:registered).remap { |k,v| [k, v[:symbol]] }
    #{:owner => '~', :admin => '&', :operator => '@', :halfop => '%', :voice => '+'}
    params = string.match /(?<prefix>[\+%@&~]*)(?<nick>\S+)/
    modes.each {|key, val| modes[key] = params[:prefix].include?(val)}
    return params[:nick], modes
  end

  def parse_user_modes new_modes, mode_hash
    mode = true
    map = @mode_list.remap { |k,v| [v[:prefix], k] }
    new_modes.each do |c|
      mode = (c=="+") ? true : (c == "-" ? false : mode)
      next if "+- ".include?(c)
      next unless map[c] # tempfix: skip any unknown modes (that probably belong to chan)
      mode_hash[map[c]] = mode # mode is either true (add) or false (remove)
    end
  end

  # Global methods

  # // Using a C styled approach (Pointer mode_array),
  def self.parse_modes new_modes, mode_array
    mode = true
    new_modes.each do |c|
      mode = (c=="+") ? true : (c == "-" ? false : mode)
      next if "+- ".include?(c)
      if mode
        mode_array << c unless mode_array.include?(c)
      else
        mode_array.subtract_once(c)
      end
    end
  end

  def self.parse_esc_codes msg, remove=false # parses IRC escape codes into ANSI or removes them.
    new_msg = msg.gsub(/\x02(.+?)\x02/) {
      remove ?  "#{$1}" : "\x1b[1m#{$1}\x1b[22m"
    }
    new_msg = new_msg.gsub(/\x1F(.+?)\x1F/) {
      remove ?  "#{$1}" : "\x1b[4m#{$1}\x1b[24m"
    }
    new_msg
  end
  
  def self.parse_line line
    matches = line.match /^(:(?<prefix>\S+)\s+)?(?<command>\S+)\s+(?<params>.*)\s*/
    result = Hash[matches.names.map(&:to_sym).zip(matches.captures)]
    params = result[:params].match(/\A(?::)?(?<pieces>.+?)((?:^|\s):(?<rest>.+)\s*)?\z/) # params prefixed with : are separate.
    
    result[:params] = params[:pieces].split
    result[:params] << params[:rest] if params[:rest]
    result[:params].delete("")

    result[:prefix] ||= ""
    result[:target] = result[:params].slice!(0)
    return result
  end
end