# A parser class, wrapping the common tasks of parsing various IRC message types.
module Scarlet
  class Parser
    # Contains a map of the de facto user mode list.
    @@base_mode_list = {
      owner:      { name: 'owner'     , prefix: 'q', symbol: '~'},
      admin:      { name: 'admin'     , prefix: 'a', symbol: '&'},
      op:         { name: 'operator'  , prefix: 'o', symbol: '@'},
      hop:        { name: 'halfop'    , prefix: 'h', symbol: '%'},
      voice:      { name: 'voice'     , prefix: 'v', symbol: '+'},
      registered: { name: 'registered', prefix: 'r', symbol: '' }
    }

    # Creates a new instance of the parser, mapping @mode_list to the list of modes
    # available on the network, by parsing the +prefix_list+.
    # @param [String] prefix_list The ISUPPORT prefix string.
    def initialize(prefix_list)
      name_lookup = @@base_mode_list.remap { |k,v| [v[:prefix], k] }
      #prefix_list.match(/\((?<prefix>\w+)\)(?<symbol>.+)/) {|matches|
      #  Hash[matches[:prefix].split("").zip(matches[:symbol].split(""))]
      #}
      # TODO: use the symbol that's in the prefix_list for the prefix's symbol.
      parsed = prefix_list.match(/\((?<prefix>\w+)\)(?<symbol>.+)/)
      prefixes = parsed[:prefix].split("").each_with_object([]) {|prefix, array| array << name_lookup[prefix] }
      @mode_list = @@base_mode_list.slice(*prefixes)
    end

    def self.parse_isupport params
      hash = {}
      params.each do |segment|
        if s = segment.match(/(?<token>.+)\=(?<params>.+)/)
          if s[:params].include? ':'
            val = Hash[s[:params].scan(/([^,]+):([^,]+)/).map {|(k,v)| [k.downcase.to_sym, convert_digit(v)]}]
          elsif s[:params].include? ',' # convert arrays and it's digit keys
            val = s[:params].split(',').map {|c| convert_digit(c)}
          else
            val = convert_digit(s[:params])
          end
          hash[s[:token].downcase.to_sym] = val
        else
          hash[segment.downcase.to_sym] = true
        end
      end
      hash
    end
    # converts val to int if it's made from digits only
    def self.convert_digit val
      val.match(/^[[:digit:]]+$/) ? val.to_i : val
    end

    # Parses NAMES list.
    # @param [String] string The NAMES list string which includes the user and
    #  his prefixes.
    def parse_names_list string
      modes = @mode_list.except(:registered).remap { |k,v| [k, v[:symbol]] }
      #{:owner => '~', :admin => '&', :operator => '@', :halfop => '%', :voice => '+'}
      params = string.match /(?<prefix>[\+%@&~]*)(?<nick>\S+)/
      modes.each {|key, val| modes[key] = params[:prefix].include?(val)}
      return params[:nick], modes
    end

    # Works in a similar manner as +#parse_modes+, except that it works with
    # hashes which contain a certain user's modes.
    # @param [String] new_modes The mode string we recieved on MODE message.
    # @param [Array] mode_hash The hash we want to apply the mode changes to.
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

    # Goes trough the +new_modes+ string char by char and makes changes accordingly
    # on +mode_array+.
    # @param [String] new_modes The mode string we recieved on MODE message.
    # @param [Array] mode_array The array we want to apply the mode changes to.
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

    # Parses IRC escape codes into ANSI or removes them.
    # @param [String] msg The message to parse.
    # @param [Boolean] remove True if we want to remove the IRC code and not parse
    #  it to ANSI.
    def self.parse_esc_codes msg, remove = false
      new_msg = msg.gsub(/\x02(.+?)\x02/) do
        remove ?  "#{$1}" : "\x1b[1m#{$1}\x1b[22m"
      end
      new_msg = new_msg.gsub(/\x1F(.+?)\x1F/) do
        remove ?  "#{$1}" : "\x1b[4m#{$1}\x1b[24m"
      end
      new_msg
    end

    # Parses the message sent by the server into several distinct parts:
    # prefix, command, params and target.
    # @param [String] line The raw line message we got from the server.
    # @return [Hash] A hash containing the parsed message parts.
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
end
