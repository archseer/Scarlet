Scarlet.hear (/what\'s playing\??/) do |event, matches|
  if $bird
    song = $bird.current_song
    target = event.target == $config.irc_bot.nick ? event.sender.nick : event.target
    message = ["Now playing"]
    message << (song.title ? "\"#{song.title}\"" : message << "\"#{File.basename(song.file)}\"")
    message << "by \"#{song.artist}\"" if song.artist
    message << "from the album \"#{song.album}\"" if song.album
    msg target, "#{message.join(' ')}."
  else
    msg target, "Cardinal is not running at the moment."
  end
end

Scarlet.hear (/(?:play )?next(?: song[.!]?)?/) do |event, matches|
  if $bird
    $bird.next
    song = $bird.current_song
    target = event.target == $config.irc_bot.nick ? event.sender.nick : event.target
    msg target, "...and next song."
  else
    msg target, "Cardinal is not running at the moment."
  end
end