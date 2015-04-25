require 'scarlet/helpers/http_command_helper'

hear (/rubygems gem\s+(?<gemname>.+)/) do
  clearance :any
  description 'Displays information about a gem <gemname>.'
  usage 'rubygems gem <gemname>'
  helpers Scarlet::HttpCommandHelper
  on do
    http = json_request("https://rubygems.org/api/v1/gems/#{params[:gemname]}.json").get
    http.errback { reply 'ERROR: rubygems gem' }
    http.callback do
      if r = http.response.value.presence
        r.symbolize_keys!
        reply "[%<platform>s gem] %<name>s (%<version>s) : %<info>s #{fmt.uri(r[:homepage_uri])}" % r
      else
        reply "No gem #{params[:gemname]}"
      end
    end
  end
end

hear (/rubygems search\s+(?<name>.+)/) do
  clearance :any
  description 'Searchs for gems with <name>'
  usage 'rubygems search <name>'
  helpers Scarlet::HttpCommandHelper
  on do
    http = json_request('https://rubygems.org/api/v1/search.json').get query: { query: params[:name] }
    http.errback { reply 'ERROR: rubygems search' }
    http.callback do
      if r = http.response.value.presence
        result = []
        r.each do |h|
          h.symbolize_keys!
          result << ("%<name>s (%<version>s)" % h)
        end
        reply "Search Result: #{result.join(', ')}"
      else
        reply "No results for #{params[:name]}"
      end
    end
  end
end
