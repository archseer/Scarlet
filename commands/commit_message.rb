# commit message - Displays a random commit message
hear /commit-message/i, :registered do
  EventMachine::HttpRequest.new('http://whatthecommit.com/index.txt').get.callback {|http| reply http.response }
end
