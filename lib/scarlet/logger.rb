require 'logger'
require 'colorize'

class Scarlet
  class << self
    attr_accessor :logger
  end

  module LogFormatter
    class << self
      attr_accessor :colors
    end

    self.colors = {
      'DEBUG' => :default,
      'INFO' => :light_blue,
      'WARN' => :light_red,
      'ERROR' => :red,
      'FATAL' => :red,
      'UNKNOWN' => :default,
    }

    def self.call(severity, datetime, progname, msg)
      msg = Parser.parse_esc_codes msg
      "[#{Time.now.strftime("%T")}] #{msg}\n".colorize(colors[severity])
    end
  end

  module Loggable
    def logger
      Scarlet.logger
    end
  end

  self.logger = Logger.new(STDOUT)
  logger.formatter = LogFormatter

  include Loggable
end
