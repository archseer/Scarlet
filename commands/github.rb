require 'octokit'
require 'scarlet/helpers/http_helper'

hear(/gh status/) do
  clearance nil
  description 'Displays latest message from github.status'
  usage 'gh status'
  helpers Scarlet::HttpHelper
  on do
    http = json_request('https://status.github.com/api/last-message.json').get
    http.errback { reply 'ERR!' }
    http.callback do
      if data = http.response.value
        t = fmt.digital_time(Time.parse(data['created_on']))
        reply "(#{t}) [#{data['status']}] #{data['body']}"
      else
        reply 'Errrrrrrrrooooooooooooorrrr! (github status failed or something)'
      end
    end
  end
end

display_commit = lambda do |repo, sha, branch = nil|
  begin
    commits = Octokit.commits(repo, branch.presence)
    commit = if sha.present?
      commits.find { |c| c[:sha].start_with?(sha) }.presence
    else
      commits.first
    end
    if commit.presence
      data = commit[:commit]
      csha = commit[:sha]
      author_name = data[:author][:name]
      msg = data[:message]
      url = commit[:html_url]
      reply "#{repo} #{fmt.commit_sha(csha)} #{author_name}: #{msg} #{fmt.uri(url)}"
    else
      reply "Commit #{sha} not found"
    end
  rescue Octokit::NotFound
    reply "No commits for #{repo}"
  end
end

display_issue = lambda do |repo, issue|
  begin
    i = Octokit.issue(repo, issue)
    reply("github/#{repo}: %<title>s #{fmt.uri(i['html_url'])}" % i)
  rescue Octokit::NotFound
    reply 'Repository or issue does not exist.'
  end
end

display_repo = lambda do |reponame|
  begin
    repo = Octokit.repo(reponame)
    msg = "%<full_name>s: %<description>s #{fmt.uri(repo['html_url'])}" % repo
    msg = "@#{msg}" if repo['fork']
    reply msg
  rescue Octokit::NotFound
    reply "Repository #{reponame} not found"
  end
end

display_user = lambda do |username|
  begin
    user = Octokit.user(username)
    reply "%<login>s #{fmt.uri(user['html_url'])}" % user
  rescue Octokit::NotFound
    reply "User #{username} not found"
  end
end

hear(/gh (?<path>(?<user>[\w\-_\.]+)(?:\/(?<repo>[\w\-_\.]+))?)(?:\#(?<issue>\d+)|\@(?<commit_sha>\w+))?/) do
  clearance nil
  description 'General github command'
  usage 'gh (<user>|<user>/<repo>[:branch][(#<issue>|@<commit>)]'
  on do
    commit_sha = params[:commit_sha].presence
    issue = params[:issue].presence
    repo = params[:repo].presence
    path = params[:path]
    username = params[:user]
    if repo && commit_sha # a repoistory and commit was provided
      instance_exec(path, commit_sha, nil, &display_commit)
    elsif repo && issue # a repoistory and issue was provided
      instance_exec(path, issue.to_i, &display_issue)
    elsif repo # a repository was provided
      instance_exec(path, &display_repo)
    else
      instance_exec(username, &display_user)
    end
  end
end

hear(/gh search repos\s+(?<terms>.+)/i) do
  clearance(&:registered?)
  description 'Searches github for reposistories using the provided search <terms>.'
  usage 'gh search repos <terms>'
  on do
    terms = params[:terms]
    result = Octokit.search_repositories(terms)
    if (tc = result[:total_count]) > 0
      if tc > 5
        reply "Got #{tc} result (only showing first 5)"
      else
        reply "Got #{tc} #{tc > 1 ? 'results' : 'result'}"
      end

      [tc, 5].min.times do |i|
        repo = result[:items][i]
        next unless repo
        reply "%<full_name>s: %<description>s #{fmt.uri(repo[:html_url])}" % repo
      end
    else
      reply "Nobody here but us chickens."
    end
  end
end
