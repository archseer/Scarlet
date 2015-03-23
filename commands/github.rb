require 'octokit'

hear (/gh commit\s+(?<repo>\S+)(?:\s+:(?<branch>\S+))?(?:\s+(?<sha>\S+))?/i) do
  clearance :registered
  usage 'gh commit <repo> [<sha>]'
  on do
    repo = params[:repo]
    sha = params[:sha] # might be partial
    branch = params[:branch]
    if commits = Octokit.commits(repo, branch.presence).presence
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
        reply "#{repo} #{csha[0...8]} #{author_name}: #{msg}"
      else
        reply "Commit #{sha} not found"
      end
    else
      reply "No commits for #{repo}"
    end
  end
end

hear (/gh user\s+(?<username>\S+)(?:\s+(?<fmt>.+))?/i) do
  clearance :registered
  description 'Prints user information, format is a valid ruby formatting string with keynames.'
  usage 'gh user <username> <fmt>'
  on do
    username = params[:username]
    if data = Octokit.user(username).presence
      fmt = params[:fmt].presence || "%<login>s (%<html_url>s)"
      reply (fmt % data)
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
    if i = Octokit.issue(reponame, issue).presence
      reply ("github/#{reponame}: %<title>s (%<html_url>s)" % i)
    else
      reply 'Repo or issue did not exist.'
    end
  end
end
