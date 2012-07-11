# commit message - Displays a random commit message
Scarlet.hear /commit\smessage/i do
  http = EventMachine::HttpRequest.new('http://whatthecommit.com/index.txt').get.callback { reply http.response }
end