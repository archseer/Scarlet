hear (/version/i) do
  clearance :any
  description 'Displays the version information.'
  usage 'version'
  on do
    reply "Scarlet v#{Scarlet::Version::STRING}"
  end
end

hear (/reload commands/i) do
  clearance :dev
  description 'Loads all available commands.'
  usage 'reload commands'
  on do
    if Scarlet::Command.load_commands
      notify "Commands loaded."
    else
      notify "Command loading failed."
    end
  end
end

hear (/reload command\s+(\w+)/i) do
  clearance :dev
  description 'Loads a command set from the commands directory.'
  usage 'reload command <name>'
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
