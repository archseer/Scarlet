hear(/set my dob (?<year>\d+) (?<month>\d+) (?<day>\d+)/) do
  clearance(&:registered?)
  description 'Sets your dob setting'
  usage 'set my dob <year> <month> <day>'
  on do
    with_nick sender.nick do |nick|
      nick.settings[:dob] = Time.at(params[:year].to_i, params[:month].to_i, params[:day].to_i).to_i

      notify "Okay, I've set your dob to #{fmt.time(Time.at(nick.settings[:dob]))}"
    end
  end
end

hear(/age(?: (?<nick>\S+))?/) do
  clearance nil
  description "Displays a user's age, or your own if no nick is given"
  usage 'age [<nick>]'
  on do
    with_nick params[:nick] || sender.nick do |nick|
      if dob = nick.settings[:dob]

      else
        if params[:nick] == nick.nick
          reply "You have not set your dob"
        else
          reply "#{nick[:dob]} has not set their dob"
        end
      end
    end
  end
end
