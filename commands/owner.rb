hear (/(?:who(?:'s| is)|whose) your daddy\?/) do
  clearance :any
  description 'Ask the bot who its owner is.'
  on do
    n = Scarlet::Nick.where(privileges: 9).first
    if n
      reply "#{n.nick} is my daddy!"
    else
      reply "I'm an orphan!"
    end
  end
end
