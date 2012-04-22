Scarlet.hear /google (.+)/ do
  http = EventMachine::HttpRequest.new('http://ajax.googleapis.com/ajax/services/search/web').get :query => {'v' => '1.0', 'q' => params[1]}
  http.errback { reply "ERROR! Fatal mistake." }
  http.callback {
    results = JSON.parse(http.response)
    reply results['responseData']['results'][0]['url']
  }
end