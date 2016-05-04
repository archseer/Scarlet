require 'uri'
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
      if value = http.response.value
        responseData = value['responseData'] || {}
        reply(if results = responseData['results'].presence
          URI.unescape(results.first['url'])
        else
          "No search result found."
        end)
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
