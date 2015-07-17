hear (/help(?:\s*(?<query>.*))/i) do
  clearance nil
  description 'Displays the help for a command, if a command is given displays the help associated with that command'
  usage 'help [<query>]'
  on do
    query = params[:query].presence
    helps = event.data[:commands].get_help(query)
    if helps.blank?
      reply "I'm sorry I didn't find a (#{query}) command that matched."
    else
      helps.each do |line|
        notify line
      end
    end
  end
end
