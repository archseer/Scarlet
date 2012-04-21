base_path = File.expand_path File.dirname(__FILE__)
load base_path + '/../../../../mpd-ruby/cardinal.rb'
$bird = Cardinal.new

Scarlet.hear (/what\'s playing\??/) do
  targ = target == $config.irc_bot.nick ? sender.nick : target
  if $bird
    if $bird.current_song
      song = $bird.current_song
      message = ["Now playing"]
      message << (song.title ? "\"#{song.title}\"" : message << "\"#{File.basename(song.file)}\"")
      message << "by \"#{song.artist}\"" if song.artist
      message << "from the album \"#{song.album}\"" if song.album
      msg targ, "#{message.join(' ')}."
    else
      msg targ, "No song playing."
    end
  else
    msg targ, "Cardinal is not running at the moment."
  end
end

Scarlet.hear (/(?:play )?next(?: song[.!]?)?/) do
  targ = target == $config.irc_bot.nick ? sender.nick : target
  if $bird
    $bird.next
    song = $bird.current_song
    msg targ, "...and next song."
  else
    msg targ, "Cardinal is not running at the moment."
  end
end

Scarlet.hear (/volume (.*)/) do
  targ = target == $config.irc_bot.nick ? sender.nick : target
  if $bird
    $bird.volume = params[1].to_i
    msg targ, "I have changed the volume for you."
  else
    msg targ, "Cardinal is not running at the moment."
  end
end