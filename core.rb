#!/usr/bin/env ruby
require_relative 'scarlet'
MongoMapper.database = 'scarlet'

Scarlet.run!
