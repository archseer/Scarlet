require 'scarlet/time'

# BECAUSE I CANT DEFINE METHODS HERE.
with_dob = lambda do |&block|
  lambda do |nick|
    if dob = nick.settings[:dob]
      instance_exec(dob, &block)
    else
      if params[:nick] == nick.nick
        reply "You have not set your dob"
      else
        reply "#{nick.nick} has not set their dob"
      end
    end
  end
end

hear(/set my dob (?<year>\d+) (?<month>\d+) (?<day>\d+)/) do
  clearance(&:registered?)
  description 'Sets your dob setting'
  usage 'set my dob <year> <month> <day>'
  on do
    with_nick sender.nick do |nick|
      nick.update_settings(dob: Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i))
      notify "Okay, I've set your dob to #{fmt.date(nick.settings[:dob])}"
    end
  end
end

hear(/birthday(?: (?<nick>\S+))?/) do
  clearance nil
  description "Displays a user's date of birth"
  usage 'birthday [<nick>]'
  on do
    with_nick params[:nick] || sender.nick do |nick|
      instance_exec(nick, &(with_dob.call do |dob|
        reply "#{nick.nick} was born #{fmt.date(dob)}"
      end))
    end
  end
end

hear(/age(?: (?<nick>\S+))?/) do
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
