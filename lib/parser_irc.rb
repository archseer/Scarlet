class IRC
  module Parser  
    def self.parse(line_orig)
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

      target = params[0]
      params.slice! 0
      
      {:prefix => prefix, :command => command, :target => target, :params => params}
    end
  end
end