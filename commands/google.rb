# google <terms> - Returns the first result on google matching <terms>.
Scarlet.hear /google (.+)/ do
  http = EventMachine::HttpRequest.new('http://ajax.googleapis.com/ajax/services/search/web').get :query => {'v' => '1.0', 'q' => params[1]}
  http.errback { reply "ERROR! Fatal mistake." }
  http.callback {
    results = JSON.parse(http.response)
    message = !results['responseData']['results'].empty? ? results['responseData']['results'][0]['url'] : "No search result found."
    reply message
  }
end
