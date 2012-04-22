base_path = File.expand_path File.dirname(__FILE__)
load base_path + '/../../../../mpd-ruby/cardinal.rb'
$bird = Cardinal.new

Scarlet.hear (/what\'s playing\??/) do
  if $bird
    if $bird.current_song
      song = $bird.current_song
      message = ["Now playing"]
      message << (song.title ? "\"#{song.title}\"" : message << "\"#{File.basename(song.file)}\"")
      message << "by \"#{song.artist}\"" if song.artist
      message << "from the album \"#{song.album}\"" if song.album
      reply "#{message.join(' ')}."
    else
      reply "No song playing."
    end
  else
    reply "Cardinal is not running at the moment."
  end
end

Scarlet.hear (/(?:play )?next(?: song[.!]?)?/) do
  if $bird
    $bird.next and reply "...and next song."
  else
    reply "Cardinal is not running at the moment."
  end
end

Scarlet.hear (/volume (.*)/) do
  if $bird
    $bird.volume = params[1].to_i
    reply "I have changed the volume for you."
  else
    reply "Cardinal is not running at the moment."
  end
end

# SoundCloud support. Experimental!

Scarlet.hear (/play favourites/) do
  if $bird
    http = EventMachine::HttpRequest.new('http://api.soundcloud.com/resolve.json').get :query => {
      'url' => "http://soundcloud.com/speed-4/favorites", 'client_id' => 'YOUR_CLIENT_ID'}, :redirects => 1
    http.errback { reply "ERROR! Fatal mistake." }
    http.callback {
      JSON.parse(http.response).each { |fav| $bird.queue "#{fav['stream_url']}?client_id=YOUR_CLIENT_ID" }
      reply "SoundCloud tracks queued."
    }
  else
    reply "Cardinal is not running at the moment."
  end
end