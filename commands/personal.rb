hear (/login/i) do
  clearance nil
  description 'Logs the user into his bot account.'
  usage 'login'
  on do
    if Scarlet::Nick.first(nick: sender.nick)
      if !sender.user.ns_login
        server.check_ns_login sender.nick
        notify "#{sender.nick}, you have been logged in successfuly."
      else
        notify "#{sender.nick}, you are already logged in!"
      end
    else
      notify "#{sender.nick}, you do not have an account yet. Type !register."
    end
  end
end

hear (/logout/i) do
  clearance &:registered?
  description 'Logs the user out from his bot account.'
  usage 'logout'
  on do
    if sender.user.ns_login
      sender.user.ns_login = false
      notify "#{sender.nick}, you are now logged out."
    end
  end
end

hear (/register/i) do
  clearance nil
  description 'Registers an account with the bot.'
  usage 'register'
  on do
    if !Scarlet::Nick.first(nick: sender.nick)
      Scarlet::Nick.create(nick: sender.nick)
      notify "Successfuly registered with the bot."
    else
      notify "ERROR: You are already registered!"
    end
  end
end
