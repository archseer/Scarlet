require 'octokit'
require 'scarlet/helpers/http_command_helper'

hear (/gh status/) do
  clearance :any
  description 'Displays latest message from github.status'
  usage 'gh status'
  helpers Scarlet::HttpCommandHelper
  on do
    http = json_request('https://status.github.com/api/last-message.json').get
    http.errback { reply 'ERR!' }
    http.callback do
      if data = http.response.value
        reply "(#{data['created_on']}) [#{data['status']}] #{data['body']}"
      else
        reply 'Errrrrrrrrooooooooooooorrrr! (github status failed or something)'
      end
    end
  end
end

hear (/gh commit\s+(?<repo>\S+)(?:\s+:(?<branch>\S+))?(?:\s+(?<sha>\S+))?/i) do
  clearance :registered
  usage 'gh commit <repo> [<sha>]'
  on do
    repo = params[:repo]
    sha = params[:sha] # might be partial
    branch = params[:branch]
    commits = begin
      Octokit.commits(repo, branch.presence)
    rescue Octokit::NotFound
    end
    if commits
      commit = if sha.presence
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
    else
      reply "No commits for #{repo}"
    end
  end
end

hear (/gh repo\s+(?<reponame>\S+)/) do
  clearance :registered
  description ''
  usage 'gh repo <reponame>'
  on do
    reponame = params[:reponame]
    repo = begin
      Octokit.repo(reponame)
    rescue Octokit::NotFound
    end
    if repo
      msg =  "%<full_name>s: %<description>s #{fmt.uri(repo['html_url'])}" % repo
      msg = "@#{msg}" if repo['fork']
      reply msg
    else
      reply "No repo #{reponame}"
    end
  end
end

hear (/gh user\s+(?<username>\S+)(?:\s+(?<fomt>.+))?/i) do
  clearance :registered
  description 'Prints user information, format is a valid ruby formatting string with keynames.'
  usage 'gh user <username> <fmt>'
  on do
    username = params[:username]
    data = begin
      Octokit.user(username)
    rescue Octokit::NotFound
    end
    if data
      fomt = params[:fomt].presence || "%<login>s #{fmt.uri(data['html_url'])}"
      reply (fomt % data)
    else
      reply "User #{username} not found"
    end
  end
end

hear (/gh issue\s+(?<repo>\S+)\s+\#(?<issue>\d+)/i) do
  clearance :registered
  description 'Prints out a github issue.'
  usage 'gh issue <repo> #<issue_number>'
  on do
    reponame = params[:repo]
    issue = params[:issue].to_i
    i = begin
      Octokit.issue(reponame, issue)
    rescue Octokit::NotFound
    end
    if i
      reply ("github/#{reponame}: %<title>s #{fmt.uri(i['html_url'])}" % i)
    else
      reply 'Repo or issue did not exist.'
    end
  end
end
