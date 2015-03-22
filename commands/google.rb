require 'cgi'
require 'scarlet/helpers/http_command_helper'
require 'scarlet/helpers/json_command_helper'

hear (/google\s+(.+)/) do
  clearance :any
  description 'Harness the power of google!'
  usage 'google <terms>'
  helpers Scarlet::HttpCommandHelper, Scarlet::JsonCommandHelper
  on do
    http = http_request('http://ajax.googleapis.com/ajax/services/search/web').get :query => {'v' => '1.0', 'q' => params[1]}
    http.errback { reply "ERROR! Fatal mistake." }
    http.callback do
      results = parse_json http.response
      message = !results['responseData']['results'].empty? ? results['responseData']['results'][0]['url'] : "No search result found."
      reply message
    end
  end
end

hear (/lmgtfy\s+(.+)/) do
  clearance :any
  description 'Lemme google that for you.'
  usage 'lmgtfy <request>'
  on do
    reply "http://lmgtfy.com/?q=#{CGI.escape(params[1])}"
  end
end
