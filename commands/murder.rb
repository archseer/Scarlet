# murder core - Quotes one of GLaDOS's murder quotes.
Scarlet.hear /murda core/ do
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
reply quotes.sample
end
# murder - Returns a random kill scenario for the killing of random user.
# murder <user> - Returns a random kill scenario for the killing of the specified user.
Scarlet.hear /murder(?:\s(\S+))?/ do
  quotes = [
    "puts a bullet to %s head",
    "snaps %s's neck",
    "uppercuts %s"
  ]
  u = server.channels[channel].users.keys.sample
  action quotes.sample % context_nick(params[1]||u)
end