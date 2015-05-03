require 'fileutils'
require 'tmpdir'
require 'simplecov'

def fixture_pathname(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end

SimpleCov.start
require 'scarlet'

Scarlet.config.db ||= {}
Scarlet.config.db[:path] = fixture_pathname('db/models')
