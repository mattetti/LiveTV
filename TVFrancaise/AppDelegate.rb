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
  attr_accessor :split_view
  
  def applicationDidFinishLaunching(a_notification)
    # full screen mode for Lion only
    if Object.const_defined?(:NSWindowCollectionBehaviorFullScreenPrimary)
      window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary   
      NSNotificationCenter.defaultCenter.addObserver( self, 
                                                   selector: 'will_enter_fullscreen:',
                                                   name: NSWindowWillEnterFullScreenNotification,
                                                   object: window)
      NSNotificationCenter.defaultCenter.addObserver( self, 
                                                     selector: 'will_exit_fullscreen:',
                                                     name: NSWindowWillExitFullScreenNotification,
                                                     object: window)
    end
  end
  
  def awakeFromNib
    @spinner.displayedWhenStopped = false
    @player.hidden = true
				channel_plist_path = NSBundle.mainBundle.pathForResource "channelList", ofType:"plist"
				@data = NSArray.arrayWithContentsOfFile channel_plist_path
    outline.expandItem(@data[0])
    # Starting channel
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

  def outlineView(outlineView, shouldSelectItem:item)
    return false if item.kind_of?(Hash)
    stream_channel(item)
    return true
  end

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
      movie = QTMovie.movieWithAttributes({QTMovieOpenForPlaybackAttribute => true, QTMovieURLAttribute => url}, error)
      @loading_check_thread.exit if @loading_check_thread
      @loading_check_thread = Thread.new do
        @player.hidden = true unless @player.movie
        while(movie.attributeForKey(QTMovieLoadStateAttribute) == QTMovieLoadStateLoading) do
          # puts "loading..."
          sleep(0.5) 
        end
        movie.autoplay
        @player.hidden = false
        @spinner.stopAnimation(nil)
        @player.setMovie(movie)
      end
      @last_item = item
    end
  end
    
  def will_enter_fullscreen(notification)
    # about to enter Lion's FS mode, collapsing the channel list panel
    @channel_panel_old_size = [split_view.subviews[0].frame[0].x, 
                               split_view.subviews[0].frame[0].y, 
                               430, #split_view.subviews[0].frame[1].width
                               split_view.subviews[0].frame[1].height]
    split_view.subviews[0].frame = [0, 0, 0, split_view.subviews[0].frame[1].height]    
  end
    
  def will_exit_fullscreen(notification)
    # resizing the channel panel
    split_view.subviews[0].frame = @channel_panel_old_size if @channel_panel_old_size
  end
    
  def windowWillClose(sender); exit(1); end
  
end

