lib = File.join(File.dirname(__FILE__), 'lib')
$:.unshift lib unless $:.include?(lib)

require 'scarlet/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'scarlet'
  s.summary     = 'A buggy IRC bot'
  s.description = 'A buggy IRC bot.'
  s.date        = Time.now.to_date.to_s
  s.version     = Scarlet::Version::STRING
  s.homepage    = 'https://github.com/archSeer/Scarlet/'
  s.license     = 'MIT'

  s.authors = ['Blaž Hrastnik', 'Corey Powell']

  s.require_path = 'lib'
  s.executables = Dir.glob('bin/*').map { |s| File.basename(s) }
  s.files = ['Gemfile']
  s.files.concat Dir.glob('{bin,lib,spec}/**/*.{rb}')
end
