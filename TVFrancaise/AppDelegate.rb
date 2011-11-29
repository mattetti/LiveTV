#
#  AppDelegate.rb
#  TVFrancaise
#
#  Created by Matt Aimonetti on 11/27/11.
#  Copyright 2011
#

class AppDelegate
  attr_accessor :window
  attr_accessor :outline
  attr_accessor :player
  attr_accessor :spinner
  
  def applicationDidFinishLaunching(a_notification)
  end
  
  def awakeFromNib
    @spinner.displayedWhenStopped = false
    @player.hidden = true
    @data = [
     {:group => 'Chaines Françaises',
      :child => [
        {"France 2" => "http://94.247.234.2/streaming/francetv_ft2/ipad.m3u8"},
        {"France 3" => "http://94.247.234.2/streaming/francetv_ft3/ipad.m3u8"},
        {"France 4" =>  "http://94.247.234.2/streaming/francetv_ft4/ipad.m3u8"},
        {"France 5" => "http://94.247.234.4/streaming/francetv_ft5/ipad.m3u8"},
        {"France Ô" => "http://94.247.234.4/streaming/francetv_fto/ipad.m3u8"},
        {"M6"       => "http://m6-hls-live.adaptive.level3.net/apple/m6replay_iphone/m6live/m6live_ipad.m3u8"},
        {"W9"       => "http://m6-hls-live.adaptive.level3.net/apple/m6replay_iphone/m6live/w9live.m3u8"},
        {"NRJ12"    => "http://nrj-apple-live.adaptive.level3.net/apple/nrj/nrj/nrj12.m3u8"},
        {"Direct Star" => "http://cupertino-streaming-1.hexaglobe.com/rtpdirectstarlive/smil:directstar-ipad.smil/playlist.m3u8"},
        {"France 24" => "http://stream7.france24.yacast.net/iphone/france24/fr/iPad.f24_fr.m3u8"},
        {"Euronews (FR)" => "http://media4.lsops.net/live/smil:euronews_fr.smil/playlist.m3u8"},
        {"BFM TV"   => "http://http5.iphone.yacast.net/iphone/bfmtv/bfmtv_ipad.m3u8"},
        {"BFM Business" => "http://stream7.bfmbiz.yacast.net/iphone/bfmbiz/bfmbiz_live01.m3u8"},
        {"NRJ Pop Rock" => "http://nrjlive-apple-live.adaptive.level3.net/apple/nrj/nrjlive-4/appleman.m3u8"},
        {"NRJ Pure"  => "http://nrjlive-apple-live.adaptive.level3.net/apple/nrj/nrjlive-3/appleman.m3u8"},
        {"NRJ Dance" => "http://nrjlive-apple-live.adaptive.level3.net/apple/nrj/nrjlive-2/appleman.m3u8"},
        {"NRJ Urban" => "http://nrjlive-apple-live.adaptive.level3.net/apple/nrj/nrjlive-1/nrjurban.m3u8"}
      ]},
      {:group => 'English Channels',
       :child => [
        {"BBC News" => "http://akamedia2.lsops.net/live/smil:bbcnews_en.smil/playlist.m3u8"},
        {"Euronews" => "http://media4.lsops.net/live/smil:euronews_en.smil/playlist.m3u8"},
        {"NASA TV" => "http://www.nasa.gov/multimedia/nasatv/NTV-Public-IPS.m3u8"},
        {"Redbull.tv" => "http://live.iphone.redbull.de.edgesuite.net/iphone.m3u8"},
        {"BBC News" => "http://akamedia2.lsops.net/live/smil:bbcnews_en.smil/playlist.m3u8"},
        {"Eurosport UK" => "http://live.iphone.eurosport.com/uk1/stc_0_0.m3u8"},
        {"Bloomberg" => "http://media4.lsops.net/live/smil:bloomber_en.smil/playlist.m3u8"},
        {"Fashion TV" => "http://217.146.95.164:8081/ch27yiphone.m3u8"}
      ]
      },
      {:group => 'Canali Italiani', 
      :child => [
        {"DEEJAY TV" => "http://flv.kataweb.it/hls/deejaytv/deejaytv.m3u8"},
        {"Rai News" => "http://iphone.sg.softspb.com/ip/15__350.m3u8"},
        {"Teleboario " => "http://91.121.222.160:1935/teleboario/teleboario.sdp/playlist.m3u8"},
        {"Sky TG24" => "http://iphone.live.sky.it/jen2011/jen2011_Layer1.m3u8"}
        ]}
    ]
    outline.expandItem(@data[0])
    stream_channel("NRJ Pure")
  end
  
  def outlineView(outlineView, child: index, ofItem: item)
    return nil if @data.nil?
    return @data[index] if item.nil?
    return item[:child][index].keys.first
  end
  
  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return @data.size if item.nil?
    return item[:child].size
  end
  
  def outlineView(outlineView, isItemExpandable:item)
    item.kind_of?(Hash)
  end
  
  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    item.kind_of?(Hash) ? item[:group] : item
  end
  
  def windowWillClose(sender); exit(1); end
  

  def outlineView(outlineView, shouldSelectItem:item)
    return false if item.kind_of?(Hash)
    stream_channel(item)
    return true
  end

=begin  
  def outlineViewSelectionDidChange(notification)
    row = outline.selectedRow
    if row > -1
      stream_channel(row-1)
    end
  end
=end
 
  def stream_channel(item)
    unless @last_item == item
      @spinner.startAnimation(nil)
      channel = @data.each do |cat| 
        match = cat[:child].detect{|(name, url)| name.keys.first == item}
        break match if match
      end
      return unless channel && channel.respond_to?(:values)
      value = channel.values.first
      url = NSURL.URLWithString(value)
      # puts "Changing channel"
      error = Pointer.new("@")
      movie = QTMovie.alloc.initWithAttributes({QTMovieOpenForPlaybackAttribute => true, QTMovieURLAttribute => url}, error)
      @loading_check_thread.exit if @loading_check_thread
      @loading_check_thread = Thread.new do
        @player.hidden = true unless @player.movie
        while(movie.attributeForKey(QTMovieLoadStateAttribute) == QTMovieLoadStateLoading) do
          # puts "loading..."
          sleep(1) 
        end
        movie.autoplay
        @player.hidden = false
        @spinner.stopAnimation(nil)
        @player.setMovie(movie)
      end
      @last_item = item
    end
  end
  
end

