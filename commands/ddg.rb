require 'scarlet/helpers/http_command_helper'

ddg = lambda do |b, search_term|
  http = b.json_request('https://api.duckduckgo.com').get query: { q: search_term, format: 'json' }
  http.errback { b.reply 'Error!' }
  http.callback do
    if data = http.response.value
      url = data['AbstractURL'].presence
      heading = data['Heading']
      abstract = data['Abstract'].presence
      if url
        b.reply "#{heading} #{b.fmt.uri(url)}"
      else
        b.reply heading
      end
      b.reply abstract if abstract
    else
      b.reply 'Invalid response data'
    end
  end
end

hear (/ddg\s+(?<search_term>.+)/) do
  clearance :any
  description 'Search for something using DuckDuckGo.'
  usage 'ddg <search_term>'
  helpers Scarlet::HttpCommandHelper
  on do
    ddg.call self, params[:search_term].strip
  end
end
