source 'https://rubygems.org'

gemspec

# Main Platform
gem 'eventmachine'
gem 'em-throttled_queue'
gem 'em-http-request', github: 'igrigorik/em-http-request'
gem 'rufus-scheduler'
gem 'multi_json' # needed for em-http-request
gem 'bson_ext'
gem 'yajl-ruby' # awesomeness

# Database
gem 'thread_safe'
gem 'moon-prototype',    github: 'IceDragon200/moon-prototype'
gem 'moon-serializable', github: 'IceDragon200/moon-serializable'
gem 'moon-data_model',   github: 'IceDragon200/moon-data_model'

# All the awesome
gem 'activesupport'

# console
gem 'colorize'

# parsing
gem 'nokogiri'

# fun stuff
gem 'chronic' # Natural language time parser
gem 'time-lord' # pretty output of 'x time ago'
gem 'octokit', '~> 3.0'
gem 'calc'

group :development, :test do
  gem 'testi', github: 'IceDragon200/testi'
  gem 'lorem'
  gem 'simplecov'
  gem 'rspec'
  gem 'yard'
  gem 'yard-delegate'
end
