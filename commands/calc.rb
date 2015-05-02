require 'calc'

hear (/calc\s+(?<problem>.+)/) do
  clearance :registered
  usage 'calc <problem>'
  on do
    problem = params[:problem]
    begin
      answer = Calc.evaluate(problem)
      reply "#{sender.nick}: #{answer}"
    rescue ZeroDivisionError
      reply "I'm sorry, Dave, I'm afraid I can't do that."
    end
  end
end
