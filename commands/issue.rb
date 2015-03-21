hear (/add issue (.+)/i) do
  clearance :dev
  description 'Logs a message on the issue tracker.'
  usage 'add issue <message>'
  on do
    Scarlet::Issue.create(:msg => params[1], :by => sender.nick)
    reply "Issue was added."
  end
end

hear (/delete issue (\d+)/i) do
  clearance :dev
  description 'Deletes issue with <id>.'
  usage 'delete issue <id>'
  on do
    id = params[1].strip.to_i
    Scarlet::Issue.sort(:created_at).all[id-1].delete
    reply "Issue ##{id} was deleted."
  end
end

hear (/count issues/i) do
  clearance :registered
  description 'Shows the total count of issue\'s.'
  usage 'count issues'
  on do
    reply "Issue count: #{Scarlet::Issue.count}"
  end
end

# show issue <id> - Shows the message of issue with <id>.
hear (/show issue (\d+)/i) do
  clearance :registered
  description 'Shows the message of issue with <id>.'
  usage 'show issue <id>'
  on do
    id = params[1].strip.to_i
    issue = Scarlet::Issue.sort(:created_at).all[id-1]
    if issue
      table = Text::Table.new
      table.head = [{:value => "Issue #{id}", :colspan => 2, :align => :center}]
      table.rows << ['Submit date:', issue.created_at.strftime("%B %d %Y, %H:%M")]
      table.rows << ['Opened by:', issue.by]
      table.align_column 1, :right
      table.rows << :separator
      issue.msg.word_wrap.split("\n").each do |line|
        table.rows << [{:value => line, :colspan => 2, :align => :center}]
      end
      table.to_s.split("\n").each {|line| reply line }
    else
      reply "Issue ##{id} could not be found."
    end
  end
end

hear (/list issues/i) do
  clearance :registered
  description 'Displays a list with the latest 10 issues.'
  usage 'list issues'
  on do
    c = Scarlet::Issue.count
    if c > 0
      issues = Scarlet::Issue.sort(:created_at.desc).limit(10).all
      table = Text::Table.new
      issues.each_with_index do |t,i|
        table.rows << [c-i, t.by, t.created_at.strftime("%B %d %Y, %H:%M")]
      end
      table.head = [{:value => 'Latest entries', :colspan => 3, :align => :center}]
      table.to_s.split("\n").each {|line| reply line }
    else
      reply "No entries found."
    end
  end
end
