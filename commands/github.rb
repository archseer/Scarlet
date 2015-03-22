require 'octokit'

hear (/gh user\s+(?<username>\S+)(?:\s+(?<fmt>.+))?/) do
  clearance :registered
  description 'Prints user information, format is a valid ruby formatting string with keynames.'
  usage 'gh user <username> <fmt>'
  on do
    username = params[:username]
    if data = Octokit.user(username)
      fmt = params[:fmt].presence || "%<login>s (%<html_url>s)"
      reply (fmt % data)
    else
      reply "User #{username} not found"
    end
  end
end

hear (/gh issue\s+(?<repo>\S+)\s+\#(?<issue>\d+)/) do
  clearance :registered
  description 'Prints out a github issue.'
  usage 'github-issue <repo> #<issue_number>'
  on do
    reponame = params[:repo]
    issue = params[:issue].to_i
    if i = Octokit.issue(reponame, issue)
      reply ("github/#{reponame}: %<title>s (%<html_url>s)" % i)
    else
      reply 'Repo or issue did not exist.'
    end
  end
end
