hear(/commit message/i) do
  clearance nil
  description 'Displays a random commit message.'
  usage 'commit message'
  helpers Scarlet::HttpHelper
  on do
    http_request('http://whatthecommit.com/index.txt').get.callback { |http| reply http.response }
  end
end
