# encoding: utf-8
Scarlet.hear /work/ do
  #w = WHCount.new("working_hours.txt")
  def p_floor(number, partition = 30)
    (number.to_f / partition).floor * partition
  end
  # p_floor rounds off number to nearest partition
  $days = {}
  $rate = 15
  $max = 20
  $total = 0
  current_date = nil

  File.readlines("working_hours.txt").each do |line|
    if line.match(/\d{2}\.\d{2}\.\d{4}/)
      date = DateTime.strptime(line, "%d.%m.%Y").to_time
      current_date = date #marks current date
      $days[date] = []
    end

    next unless (matches = line.match(/(\d{2}:\d{2})->(\d{2}:\d{2})/))
    s = matches[1].split(':')
    e = matches[2].split(':')
    length = (e[0].to_i - s[0].to_i)*60 + (e[1].to_i-s[1].to_i)
    $days[current_date] << length
  end

  puts $days
  # total calculation
  $days.values.each {|a|
    a.each {|t| $total += t}
  }
  #puts $total

  total = $days.inject(0) {|sum, (k,v)|
    puts k.strftime("# %A, #{k.day.ordinalize} %B %Y")
    all = v.inject(0){|dt, t| 
      #reply "- #{t} min"
      dt += t
    }
    #reply "->Daily total: #{all} min"
    sum += all
  }


  def weekdays_left
    DateTime.now.next_week.to_date.mjd - DateTime.now.to_date.mjd
  end

  reply "> #{total} mins or #{sprintf "%.2f", total/60.0} hours -> #{p_floor(total, 30)/60.0} rounded hours: #{p_floor(total, 30)/60 * 15}€"
  reply "#{weekdays_left} days left until next week. Still got to do #{$max - sprintf("%.2f", $total/60.0).to_f} hours." #get the amount of days till next week.
  #puts
end