require 'scarlet/commands/issues'

find_model = lambda do |top, id, model|
  # issue ids can be either the long uuid, or the short uuid, OR the issue's
  # uname, generated from the title
  model.first(id: id) || model.first(short_id: id) || model.first(uname: id)
end

find_comment = lambda do |top, issue, comment_id|
  comment = issue.comments.find do |cmt|
    cmt.id == comment_id || cmt.short_id == comment_id
  end
  top.reply "Comment #{top.fmt.id(comment_id)} not found." unless comment
  comment
end

find_issue = lambda do |top, id|
  issue = find_model.call(top, id, Scarlet::Issue)
  top.reply "Issue #{top.fmt.id(id)} not found." unless issue
  issue
end

modify_issue = lambda do |top, id, nick|
  if issue = find_issue.call(top, id)
    if nick.root? || issue.nick_id == nick.id
      issue
    else
      top.reply("You cannot modify that issue.")
      nil
    end
  end
end

modify_comment = lambda do |top, issue, comment_id, nick|
  if comment = find_comment.call(top, issue, comment_id)
    if nick.root? || issue.nick_id == nick.id
      comment
    else
      top.reply("You cannot modify that comment.")
      nil
    end
  end
end

fmt_issue = lambda do |top, issue|
  "#{top.fmt.id(issue.short_id)} #{top.fmt.id(issue.uname)}: #{issue.title}"
end

fmt_comment = lambda do |top, comment, opts = {}|
  text = opts[:short] ? comment.text[0, 64] : comment
  "#{top.fmt.id(comment.short_id)} #{top.fmt.id(comment.nick.nick)}: #{text}"
end

hear (/issue new (?<title>.+)/i) do
  clearance &:registered?
  description 'Creates a new issue'
  usage 'issue new <title>'
  on do
    with_nick sender.nick do |nick|
      issue = Scarlet::Issue.create(title: params[:title], nick_id: nick.id)
      reply "New issue created: #{fmt.id(issue.short_id)} #{issue.title}"
    end
  end
end

hear (/issue show (?<id>\S+)/i) do
  clearance nil
  description 'Displays information on an issue'
  usage 'issue show <id>'
  on do
    if issue = find_issue.call(self, params[:id])
      reply "Issue #{fmt_issue.call(self, issue)}"
    end
  end
end

hear (/issue list/i) do
  clearance nil
  description 'Displays a list of issues'
  usage 'issue list'
  on do
    issues = Scarlet::Issue.all.map do |issue|
      "#{fmt.id(issue.uname)} #{issue.title}"
    end
    if issues.empty?
      reply "YAY! No issues!"
    else
      reply "Issues: " + issues.join(", ")
    end
  end
end

hear (/issue update (?<id>\S+) (?<title>.+)/i) do
  clearance &:registered?
  description 'Updates a given issue'
  usage 'issue update <id> <title>'
  on do
    with_nick sender.nick do |nick|
      if issue = modify_issue.call(self, params[:id], nick)
        issue.update(title: params[:title])
        reply "Updated Issue: #{fmt_issue.call(self, issue)}"
      end
    end
  end
end

hear (/issue delete (?<id>\S+)/i) do
  clearance &:registered?
  description 'Deletes a given issue'
  usage 'issue delete <id>'
  on do
    with_nick sender.nick do |nick|
      if issue = modify_issue.call(self, params[:id], nick)
        issue.destroy
        reply "Issue has been deleted"
      end
    end
  end
end

hear (/issue comment new (?<issue_id>\S+) (?<text>.+)/i) do
  clearance &:registered?
  description 'Adds a new comment to the issue'
  usage 'issue comment new <issue_id>'
  on do
    with_nick sender.nick do |nick|
      if issue = find_issue.call(self, params[:issue_id])
        comment = issue.new_comment(nick_id: nick.id, text: params[:text])
        reply "New comment added!"
      end
    end
  end
end

hear (/issue comment show (?<issue_id>\S+) (?<comment_id>\S+)/i) do
  clearance nil
  description 'Shows a specific comment for the issue'
  usage 'issue comment show <issue_id> <comment_id>'
  on do
    if issue = find_issue.call(self, params[:issue_id])
      if comment = find_comment.call(self, issue, params[:comment_id])
        reply "Comment #{fmt_comment.call(self, comment)}"
      end
    end
  end
end

hear (/issue comment list (?<issue_id>\S+)/i) do
  clearance nil
  description 'Views all comments for the given issue'
  usage 'issue comment list <issue_id>'
  on do
    if issue = find_issue.call(self, params[:issue_id])
      if issue.comments.empty?
        reply "There are no comments (yet!)"
      else
        reply "There are [#{issue.comments.size}] comment(s)"
        issue.comments.each do |comment|
          reply fmt_comment.call(self, comment, short: true)
        end
      end
    end
  end
end

hear (/issue comment update (?<issue_id>\S+) (?<comment_id>\S+) (?<text>.+)/i) do
  clearance &:registered?
  description 'Modifies an existing comment'
  usage 'issue comment update <issue_id> <comment_id> <text>'
  on do
    with_nick sender.nick do |nick|
      if issue = find_issue.call(self, params[:issue_id])
        if comment = modify_comment.call(self, issue, params[:comment_id], nick)
          comment.update(text: params[:text])
          reply "Comment has been removed"
        end
      end
    end
  end
end

hear (/issue comment delete (?<issue_id>\S+) (?<comment_id>\S+)/i) do
  clearance &:registered?
  description 'Adds a new comment to the issue'
  usage 'issue comment delete <issue_id> <comment_id>'
  on do
    with_nick sender.nick do |nick|
      if issue = find_issue.call(self, params[:issue_id])
        if comment = modify_comment.call(self, issue, params[:comment_id], nick)
          issue.comments.delete(comment)
          issue.save
          reply "Comment has been removed"
        end
      end
    end
  end
end
