# commit message - Displays a random commit message
Scarlet.hear /commit message/i do
  EventMachine::HttpRequest.new('http://whatthecommit.com/index.txt').get.callback {|http| reply http.response }
end