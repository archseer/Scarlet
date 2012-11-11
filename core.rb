#!/usr/bin/env ruby
# encoding: utf-8
require 'bundler/setup'
Bundler.require
require_relative 'scheduler'

MongoMapper.connection = Mongo::Connection.new
MongoMapper.database = 'scarlet'

puts "Loading Scarlet v1 (development)...".light_green

module Modules
  class << self
    def load_models root
      Dir["#{root}/models/**/*.rb"].each {|path| load path }
    end

    def load_libs root
      Dir["#{root}/lib/**/*.rb"].each {|path| load path }
    end
  end
end

require_relative 'scarlet'

EventMachine::run do
  Scarlet.loaded

  trap("INT") {
    Scarlet.unload
    EM.add_timer(0.1) { EM.stop }
  }
end