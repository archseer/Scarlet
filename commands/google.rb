require 'cgi'
require 'scarlet/helpers/http_helper'

hear(/(?:g|google)\s+(?<query>.+)/) do
  clearance nil
  description 'Harness the power of google!'
  usage 'google <terms>'
  helpers Scarlet::HttpHelper
  on do
    http = json_request('http://ajax.googleapis.com/ajax/services/search/web').get query: { v: '1.0', q: CGI.escape(params[:query]) }
    http.errback { reply "ERROR! Fatal mistake." }
    http.callback do
      if results = http.response.value
        message = !results['responseData']['results'].empty? ? results['responseData']['results'][0]['url'] : "No search result found."
        reply message
      else
        reply "An error occured while trying to google."
      end
    end
  end
end

hear(/lmgtfy\s+(.+)/) do
  clearance nil
  description 'Lemme google that for you.'
  usage 'lmgtfy <request>'
  on do
    reply "http://lmgtfy.com/?q=#{CGI.escape(params[1])}"
  end
end
