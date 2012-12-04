# add todo <message> - Logs a message on the TODO tracker.
Scarlet.hear /add todo (.+)/i, :dev do
  Scarlet::Todo.new(:msg => params[1], :by => sender.nick).save!
  reply "TODO was added."
end

# delete todo <id> - Deletes TODO with <id>.
Scarlet.hear /delete todo (\d+)/i, :dev do
  id = params[1].strip.to_i
  t = Scarlet::Todo.sort(:created_at).all[id-1].delete
  reply "TODO ##{id} was deleted."
end

# count todos - Shows the total count of TODO's.
Scarlet.hear /count todos/i do
  reply "TODO count: #{Scarlet::Todo.all.count}"
end

# show todo <id> - Shows the message of TODO with <id>.
Scarlet.hear /show todo (\d+)/i do
  id = params[1].strip.to_i
  todo = Scarlet::Todo.sort(:created_at).all[id-1]
  if todo
    table = Text::Table.new
    table.head = [{:value => "TODO #{id}", :colspan => 2, :align => :center}]
    table.rows << ['Date:', todo.created_at.std_format]
    table.rows << ['By:', todo.by]
    table.rows << :separator
    todo.msg.word_wrap.split("\n").each {|line| 
      table.rows << [{:value => line, :colspan => 2, :align => :center}]
    }
    table.to_s.split("\n").each {|line| reply line, true }
  else
    reply "TODO ##{id} could not be found."
  end
end

# list todos - Displays a list with the latest 10 TODO's.
Scarlet.hear /list todos/i do
  c = Scarlet::Todo.all.count
  if c > 0
    todos = Scarlet::Todo.sort(:created_at.desc).limit(10).all

    table = Text::Table.new
    todos.each_with_index { |t,i|
      table.rows << [c-i, t.by, t.created_at.std_format]
    }
    table.head = [{:value => 'Latest entries', :colspan => 3, :align => :center}]
    table.to_s.split("\n").each {|line| reply line, true }
  else
    reply "No entries found."
  end
end