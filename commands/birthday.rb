require 'scarlet/time'

# BECAUSE I CANT DEFINE METHODS HERE.
with_dob = lambda do |&block|
  lambda do |nick|
    if dob = nick.settings[:dob]
      instance_exec(dob, &block)
    else
      if params[:nick] == sender.nick
        reply "You have not set your dob"
      else
        reply "#{nick.nick} has not set their dob"
      end
    end
  end
end

hear(/set\s+my\s+dob\s+(?<date>\S+)/) do
  clearance(&:registered?)
  description 'Sets your dob setting'
  usage 'set my dob <date>'
  on do
    with_nick sender.nick do |nick|
      date = begin
        Date.parse(params[:date])
      rescue ArgumentError => ex
        error_reply ex.message
      end
      if date
        nick.update_settings(dob: date)
        notify "Okay, I've set your DOB to #{fmt.date(nick.settings[:dob])}"
      end
    end
  end
end

hear(/birthday(?:\s+(?<nick>\S+))?/) do
  clearance nil
  description "Displays a user's date of birth, or your own if no nick is given"
  usage 'birthday [<nick>]'
  on do
    with_nick params[:nick] || sender.nick do |nick|
      instance_exec(nick, &(with_dob.call do |dob|
        reply "#{nick.nick} was born #{fmt.date(dob)}"
      end))
    end
  end
end

hear(/age(?:\s+(?<nick>\S+))?/) do
  clearance nil
  description "Displays a user's age, or your own if no nick is given"
  usage 'age [<nick>]'
  helpers Scarlet::DateHelper
  on do
    with_nick params[:nick] || sender.nick do |nick|
      instance_exec(nick, &(with_dob.call do |dob|
        age = calc_age(dob)
        reply "#{nick.nick} is #{age.years.timescale} old"
      end))
    end
  end
end
