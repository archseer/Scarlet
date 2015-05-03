hear (/commit message/i) do
  clearance :any
  description 'Displays a random commit message.'
  usage 'commit-message'
  on do
    EventMachine::HttpRequest.new('http://whatthecommit.com/index.txt').get.callback { |http| reply http.response }
  end
end
