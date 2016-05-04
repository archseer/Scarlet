require 'scarlet/time'

hear(/seen (?<nick>\S+)(?:\s+last\s+(?<backlog>\d+))?/i) do
  clearance(&:registered?)
  description 'When was the last time you saw nick?'
  usage 'seen <nick> [last <count>]'
  on do
    n = [1, [(params[:backlog] || 1).to_i, 10].min].max
    logs = server.logs.nick(params[:nick]).sort_by(&:updated_at).last(n)
    if logs.blank?
      error_reply "Sorry, I have never seen #{params[:nick]}."
    end

    reply "#{params[:nick]} was last seen:"
    logs.each do |log|
      message = "#{Time.at(log.updated_at).since}"
      case log.command.downcase.to_sym
      when :privmsg
        message << " in #{log.target}" unless log.target.downcase == event.channel
        if log.message =~ /\u0001ACTION (.+)\u0001/
          message << " doing '/me #{$1}'."
        else
          message << " saying '#{log.message}'."
        end
      when :nick
        message << " changing nickname to '#{log.target}'."
      when :join
        message << " joining channel #{log.target}."
      when :part
        message << " leaving channel #{log.target}."
      when :quit
        message << " quiting IRC."
      else
        message = "Command #{log.command} not yet implemented!"
      end
      reply message
    end
  end
end
