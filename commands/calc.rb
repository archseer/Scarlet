require 'calc'

hear(/calc\s+(?<problem>.+)/) do
  clearance nil
  usage 'calc <problem>'
  on do
    problem = params[:problem]
    begin
      answer = Calc.evaluate(problem)
      reply "#{event.sender.nick}: #{answer}"
    rescue ZeroDivisionError
      reply "I'm sorry, Dave, I'm afraid I can't do that."
    end
  end
end
