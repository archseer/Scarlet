hear (/version/i) do
  clearance nil
  description 'Displays the version information.'
  usage 'version'
  on do
    reply "Scarlet v#{Scarlet::Version::STRING}"
  end
end

hear (/ruby version/i) do
  clearance nil
  description 'Displays current ruby version.'
  usage 'ruby version'
  on do
    reply "#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} [#{RUBY_PLATFORM}]"
  end
end

hear (/reload commands/i) do
  clearance &:sudo?
  description 'Loads all available commands.'
  usage 'reload commands'
  on do
    if event.data[:commands].load_commands
      notify "Commands loaded."
    else
      notify "Command loading failed."
    end
  end
end

hear (/reload command\s+(\w+)/i) do
  clearance &:sudo?
  description 'Loads a command set from the commands directory.'
  usage 'reload command <name>'
  on do
    filename = File.basename(params[0])
    begin
      event.data[:commands].load_command_rel(filename)
      notify "Command #{filename} loaded."
    rescue => ex
      notify "Command #{filename} load error: #{ex.inspect}"
    end
  end
end

