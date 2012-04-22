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
      msg return_path, "#{message.join(' ')}."
    else
      msg return_path, "No song playing."
    end
  else
    msg return_path, "Cardinal is not running at the moment."
  end
end

Scarlet.hear (/(?:play )?next(?: song[.!]?)?/) do
  if $bird
    $bird.next and msg return_path, "...and next song."
  else
    msg return_path, "Cardinal is not running at the moment."
  end
end

Scarlet.hear (/volume (.*)/) do
  if $bird
    $bird.volume = params[1].to_i
    msg return_path, "I have changed the volume for you."
  else
    msg return_path, "Cardinal is not running at the moment."
  end
end

# SoundCloud support. Experimental!

Scarlet.hear (/play favourites/) do
  if $bird
    http = EventMachine::HttpRequest.new('http://api.soundcloud.com/resolve.json').get :query => {
      'url' => "http://soundcloud.com/speed-4/favorites", 'client_id' => 'YOUR_CLIENT_ID'}, :redirects => 1
    http.errback { msg return_path, "ERROR! Fatal mistake." }
    http.callback {
      JSON.parse(http.response).each { |fav| $bird.queue "#{fav['stream_url']}?client_id=YOUR_CLIENT_ID" }
      msg return_path, "SoundCloud tracks queued."
    }
  else
    msg return_path, "Cardinal is not running at the moment."
  end
end

require 'taglib'

Scarlet.hear (/download soundcloud favourites/) do
  http = EventMachine::HttpRequest.new('http://api.soundcloud.com/resolve.json').get :query => {
    'url' => "http://soundcloud.com/speed-4/favorites", 'client_id' => 'YOUR_CLIENT_ID', 'limit' => '1'}, :redirects => 1
  http.errback { msg return_path, "ERROR! Fatal mistake." }
  base_path = File.expand_path File.dirname(__FILE__)
  http.callback {
    JSON.parse(http.response).each { |fav|
      download_link = fav["downloadable"] ? fav["download_url"] : fav['stream_url']

      song = EventMachine::HttpRequest.new("#{download_link}?client_id=YOUR_CLIENT_ID").get :redirects => 1
      song.callback {
        if song.response_header["CONTENT_DISPOSITON"]
          song.response_header["CONTENT_DISPOSITON"].match(/attachment;filename=\\"(.+)\\"/) {|m| filename = m[1] }
        else
          add_tags = true
          filename = "#{fav['title']}.mp3"
        end

        path = "#{base_path}/../../../../mpd-ruby/downloads/#{filename}"
        File.open(path, "wb") { |file| file.write(song.response)}
        if add tags = true
          TagLib::MPEG::File.open(path) do
            tag = file.id3v2_tag
            tag.title = fav['title']
            #tag.artist
          end
        end
      }
    }
  }

end