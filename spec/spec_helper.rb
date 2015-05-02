require 'fileutils'
require 'tmpdir'
require 'simplecov'

def fixture_pathname(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end

SimpleCov.start
