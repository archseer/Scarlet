hear (/login/i) do
  clearance :any
  description 'Logs the user into his bot account.'
  usage 'login'
  on do
    if !Scarlet::Nick.where(:nick => sender.nick).empty?
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
  clearance :registered
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
  clearance :any
  description 'Registers an account with the bot.'
  usage 'register'
  on do
    if !Scarlet::Nick.first(:nick => sender.nick)
      Scarlet::Nick.create(:nick => sender.nick)
      notify "Successfuly registered with the bot."
    else
      notify "ERROR: You are already registered!"
    end
  end
end

hear (/set(?:\s+my)?\s+timezone\s+(.+)/i) do
  clearance :registered
  description 'self-explanatory; used with time command'
  usage 'set timezone <timezone>'
  on do
    if nick = Scarlet::Nick.first(:nick => sender.nick)
      if TZInfo::Timezone.all_identifiers.include? params[1]
        nick.settings[:timezone] = params[1]
        notify "Your current Time Zone is: %s" % nick.settings[:timezone]
      else
        notify "Invalid Time Zone: %s" % params[1]
      end
    else
      notify "You cannot access account settings, are you logged in?"
    end
  end
end
