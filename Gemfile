source 'https://rubygems.org'

gemspec

# Main Platform
gem 'eventmachine'
gem 'em-throttled_queue'
gem 'em-http-request', github: 'igrigorik/em-http-request'
gem 'rufus-scheduler'
gem 'multi_json' # needed for em-http-request
gem 'yajl-ruby' # awesomeness

# Database
gem 'thread_safe'
gem 'moon-maybe_copy',   '>= 1.1.0', github: 'polyfox/moon-maybe_copy'
gem 'moon-prototype',    github: 'polyfox/moon-prototype'
gem 'moon-serializable', github: 'polyfox/moon-serializable'
gem 'moon-data_model',   '>= 1.0.1', github: 'polyfox/moon-data_model'
gem 'moon-repository',   github: 'polyfox/moon-repository'
gem 'moon-null_io',      github: 'polyfox/moon-null_io'

# All the awesome
gem 'activesupport', '>= 4.2.2'

# console
gem 'colorize'

# parsing
gem 'nokogiri'

# fun stuff
# Natural language time parser
gem 'chronic'
# pretty output of 'x time ago'
gem 'time-lord'
gem 'octokit', '~> 3.0'
gem 'calc'

group :development, :test do
  gem 'lorem'
  gem 'simplecov'
  gem 'codeclimate-test-reporter'
  gem 'rspec'
  gem 'yard'
  gem 'yard-delegate'
end
