# todo add <message> - Logs a message on the TODO tracker.
Scarlet.hear /todo add\s*(.+)/ do
  Scarlet::Todo.new(:msg => params[1], :by => sender.nick).save!
  reply "TODO was added."
end

# todo delete <id> - Deletes TODO with <id>.
Scarlet.hear /todo delete\s*(\d+)/, :dev do
  id = params[1].strip.to_i
  t = Scarlet::Todo.sort(:created_at).all[id-1].delete
  reply "TODO ##{id} was deleted."
end

# count todos - Shows the total count of TODO's.
Scarlet.hear /count todos/ do
  reply "TODO count: #{Scarlet::Todo.all.count}"
end

# show todo <id> - Shows the message of TODO with <id>.
Scarlet.hear /show todo\s*(\d+)/ do
  id = params[1].strip.to_i
  t = Scarlet::Todo.sort(:created_at).all[id-1]
  if t
    crt   = t.created_at.std_format.to_s
    msgs  = t.msg.word_wrap(60)
    table = Scarlet::ColumnTable.new(2,4+msgs.size)
    table.clear
    table.padding = 3
    table.set_row(0,0,"TODO"      ,"#%d"%id).set_row_color(0,0,1)
    table.set_row(0,1,"Date:"     ,crt     ).set_row_color(1,1,0)
    table.set_row(0,2,"By:"       ,t.by    ).set_row_color(2,1,0)
    table.set_row(0,3,"Entry:"    ,""      ).set_row_color(3,1,0)
    wd, pad = table.column_widths, table.padding
    table.compile.each { |line| reply line, true }
    msgs.each_with_index { |s,i| 
      reply s.align(wd,:left,pad).irc_color(1,0)
    }
  else
    reply "TODO ##{id} could not be found."
  end
end

# list todos - Displays a list with the latest 10 TODO's.
Scarlet.hear /list todos/ do
  c = Scarlet::Todo.all.count
  if c > 0
    todos = Scarlet::Todo.sort(:created_at.desc).limit(10).all
    table = Scarlet::ColumnTable.new(3,[10,c].min)
    table.clear 
    table.padding = 3
    todos.each_with_index { |t,i|
      table.set_row(0,i,"##{c-i}","\t#{t.by}\t","\t#{t.created_at.std_format}").set_row_color(i,1,0)
    }
    header = "Last 10 entries:".align(table.row_width,:center,table.padding).irc_color(0,1)
    ([header]+table.compile).each {|line| reply line, true }
  else
    reply "No entries found."
  end
end