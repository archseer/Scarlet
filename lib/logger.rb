# Simple logger utility
module Scarlet
  class Log
    def initialize
      @logs = {}
    end

    def start_log name
      @logs[name.to_sym] = File.open("#{File.dirname __FILE__}/../logs/#{name}.log", "a")
      log name.to_sym, "**** Logging started at #{Time.now.std_format}\n"
    end

    def log name, text
      @logs[name.to_sym].write "#{text}\n"
      @logs[name.to_sym].flush
    end

    def close_log name
      log name.to_sym, "**** Logging ended at #{Time.now.std_format}\n\n"
      @logs[name.to_sym].flush and @logs[name.to_sym].close
    end

    def close_all
      @logs.each {|key, l| 
        l.write("**** Logging ended at #{Time.now.std_format}\n\n") 
        l.flush and l.close 
      }
    end
  end
end