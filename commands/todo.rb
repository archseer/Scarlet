# todo add <message>
Scarlet.hear /todo add\s*(.+)/ do
  ::IrcBot::Todo.new(:msg => params[1], :by => sender.nick).save!
  reply "TODO was added."
end

# todo delete <id>
Scarlet.hear /todo delete\s*(\d+)/, :dev do
  id = params[1].strip.to_i
  t = ::IrcBot::Todo.sort(:created_at).all[id-1].delete
  reply "TODO ##{id} was deleted."
end

# count todos
Scarlet.hear /count todos/ do
  reply "TODO count: #{::IrcBot::Todo.all.count}"
end

# show todo <id>
Scarlet.hear /show todo\s*(\d+)/ do
  id = params[1].strip.to_i
  t = ::IrcBot::Todo.sort(:created_at).all[id-1]
  if t
    table = ::IrcBot::InfoTable.new(50)
    table.addHeader "TODO ##{id}"
    table.addRow "Date: #{t.created_at.std_format}"
    table.addRow "Added by: #{t.by}"
    table.addRow "Entry: #{t.msg}"
    table.compile.each {|line| reply line, true }
  else
    reply "TODO ##{id} could not be found."
  end
end

Scarlet.hear /list todos/ do
  c = ::IrcBot::Todo.all.count
  if c > 0
    table = ::IrcBot::InfoTable.new(50)
    table.addHeader "Last 10 entries:"
    ::IrcBot::Todo.sort(:created_at.desc).limit(10).each_with_index { |t, i|
      break if i == 10 
      table.addRow "##{c-i}\t#{t.by}\t\t#{t.created_at.std_format}"
    }
    table.compile.each {|line| reply line, true }
  else
    reply "No entries found."
  end
end