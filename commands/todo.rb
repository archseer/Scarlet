# todo add <message>
Scarlet.hear /todo add\s*(.+)/ do
  ::IrcBot::Todo.new(:msg => params[1], :by => sender.nick).save!
  reply "TODO was added."
end

# todo delete <id>
Scarlet.hear /todo delete\s*(\d+)/, :dev do
  id = params[1].strip.to_i - 1
  t = ::IrcBot::Todo.sort(:created_at).all[id].delete
  reply "TODO ##{id+1} was deleted."
end

# count todos
Scarlet.hear /count todos/ do
  reply "TODO count: #{::IrcBot::Todo.all.count}"
end
