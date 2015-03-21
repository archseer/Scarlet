# Help documentation
# help - Displays all of the help commands that Scarlet knows.
# help <query> - Displays all help commands that match <query>.
hear (/help(?:\s*(?<query>.*))?$/i) do
  clearance :any
  description 'Displays the help for a command, if a command is given displays the help associated with that command'
  usage 'help [<query>]'
  on do
    Scarlet::Command.get_help(params[:query].presence).each do |line|
      notify line
    end
  end
end
