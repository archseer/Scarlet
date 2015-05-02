#!/usr/bin/env ruby
# Just keep her running
loop do
  begin
    status = system 'bundle exec bin/scarlet'
    if status
      # the app closed properly, we can exit as well
      break
    else
      # the app closed with an error, restart
      puts 'Waiting 5 seconds before restarting'
      sleep 5.0
    end
  rescue Interrupt
    break
  end
end
