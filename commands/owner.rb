hear(/(?:who(?:'s| is)|whose) your daddy\?/) do
  clearance nil
  description 'Ask the bot who its owner is.'
  usage "(who's|who is|whose) your daddy?"
  on do
    n = Scarlet::Nick.owner
    if n
      reply "#{n.nick} is my daddy!"
    else
      reply "I'm an orphan!"
    end
  end
end
