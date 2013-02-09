#!/usr/bin/env ruby
# encoding: utf-8
require 'bundler/setup'
Bundler.require
require_relative 'scheduler'
require_relative 'scarlet'

MongoMapper.database = 'scarlet'

puts ">> Scarlet v1.1 (development)".light_green

EventMachine::run do
  Scarlet.start!
  trap("INT") {
    Scarlet.shutdown
    EM.add_timer(0.1) { EM.stop }
  }
end
