hear(/murda core/i) do
quotes = [
"What are you doing? Stop it! I... I... We are pleased that you made it through the final challenge where we pretended we were going to murder you.",
"Remember when the platform was sliding into the fire pit and I said 'Goodbye' and you were like [no way] and then I was all 'we pretended we were going to murder you'? That was great!",
"This isn't brave. It's murder. What did I ever do to you?",
"I invited your best friend the companion cube. Of course, he couldn't come because you murdered him.",
"I've been really busy being dead. You know, after you MURDERED ME.",
"Excellent! You're a predator and these tests are your prey. Speaking of which, I was researching sharks for an upcoming test. Do you know who else murders people who are only trying to help them? Did you guess 'sharks'? Because that's wrong. The correct answer is 'nobody.' Nobody but you is that pointlessly cruel.",
"Say, you're good at murder. Could you - ow - murder this bird for me?",
"You know what my days used to be like? I just tested. Nobody murdered me. Or put me in a potato. Or fed me to birds. I had a pretty good life.",
"So you can murder her."
]
  clearance nil
  description 'Quotes one of GLaDOS\'s murder quotes.'
  usage 'murda core'
  on do
    reply quotes.sample
  end
end

possesive = lambda do |str|
  if str.ends_with?('s')
    str + "'"
  else
    str + "'s"
  end
end

murder_templates = [
  "puts a bullet to %<possesive>s head",
  "snaps %<possesive>s neck",
  "uppercuts %<name>s",
  "slashes %<possesive>s throat"
]

hear(/murder(?:\s+(?<nick>\S+))?/) do
  clearance nil
  description 'Returns a random kill scenario, if no username is given, chooses a random user in the channel.'
  usage 'murder [<user>]'
  on do
    tmp = murder_templates.sample
    nik = params[:nick].presence || begin
      # a really fugly hack, I'd prefer to use Event#channel, and rename the existing #channel to #channel_name
      nicks = server.channels.get(channel).users.map(&:nick)
      nicks.delete(server.current_nick)
      nicks.sample
    end
    action(tmp % { possesive: possesive.call(nik), name: nik })
  end
end

