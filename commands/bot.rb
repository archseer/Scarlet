hear (/admin-load-commands/i) do
  clearance :dev
  description 'Loads all available commands'
  usage 'admin-load-commands'
  on do
    if Scarlet::Command.load_commands
      notify "Commands loaded."
    else
      notify "Command loading failed."
    end
  end
end

hear (/admin-load-command\s+(\w+)/i) do
  clearance :dev
  description 'Loads a command set from the commands directory'
  usage 'admin-load-command <name>'
  on do
    filename = File.basename(params[0])
    begin
      Scarlet::Command.load_command_rel(filename)
      notify "Command #{filename} loaded."
    rescue => ex
      notify "Command #{filename} load error: #{ex.inspect}"
    end
  end
end
