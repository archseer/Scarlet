require 'taglib'

Scarlet.hear (/download soundcloud favourites/), :owner do
  http = EventMachine::HttpRequest.new('http://api.soundcloud.com/resolve.json').get :query => {
    'url' => "http://soundcloud.com/speed-4/favorites", 'client_id' => 'YOUR_CLIENT_ID', 'limit' => '200'}, :redirects => 1
  http.errback { msg return_path, "ERROR! Fatal mistake." }
  base_path = File.expand_path File.dirname(__FILE__)
  http.callback {
    msg return_path, "Downloading..."
    JSON.parse(http.response).each { |fav|
      download_link = fav["downloadable"] ? fav["download_url"] : fav['stream_url']
      song = EventMachine::HttpRequest.new("#{download_link}?client_id=YOUR_CLIENT_ID").get :redirects => 1
      song.callback {
        if song.response_header["CONTENT_DISPOSITON"]
          song.response_header["CONTENT_DISPOSITON"].match(/.*filename=\\"(.+)\\".*/) {|m| filename = m[1] }
        else
          addtags = true
          filename = "#{fav['user']['username']} - #{fav['title'].gsub("/", "")}.mp3"
        end

        path = "#{base_path}/../../../../mpd-ruby/downloads/#{filename}"
        File.open(path, "wb") { |file| file.write(song.response)}
        if addtags == true
          file = TagLib::MPEG::File.new(path)
          tag = file.id3v2_tag
          tag.title = fav['title']
          tag.artist = fav['user']['username']
          tag.genre = fav['genre']
          tag.year = (fav['release_year'] || fav['created_at'].split("/")[0].to_i)

          # Add attached picture frame
          #apic = TagLib::ID3v2::AttachedPictureFrame.new
          #apic.mime_type = "image/jpeg"
          #apic.description = "Cover"
          #apic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
          #apic.picture = File.open("cover.jpg", 'rb') { |f| f.read }
          #tag.add_frame(apic)

          tag.comment = fav['permalink_url']
          file.save
          file.close
        end
        msg sender.nick, "Grabbed \"#{fav['user']['username']} - #{fav['title']}\""
      }
    }
  }

end