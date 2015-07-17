hear (/eval\s+(.+)/) do
  clearance &:eval?
  description 'Evals a provided string has ruby'
  usage 'eval <string>'
  on do
    begin
      t = Thread.new { Thread.current[:output] = "==> #{eval(params[1])}" }
      t.join(10)
      reply t[:output] if t[:output].size > 4
    rescue Exception  => result
      reply "ERROR: #{result.message}".irc_color(4,0)
    end
  end
end
