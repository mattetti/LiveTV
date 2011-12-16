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
  attr_accessor :split_view
  attr_accessor :leo_fullscreen_button, :is_fullscreen

  LAST_CHANNEL_KEY = "org.mattetti.livetv-lastchannel"
  
  def applicationDidFinishLaunching(notification)
    # full screen mode for Lion only
    if Object.const_defined?(:NSWindowCollectionBehaviorFullScreenPrimary)
      # remove fullscreen Leopard button
      leo_fullscreen_button.removeFromSuperview
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
    player.hidden = true
		channel_plist_path = NSBundle.mainBundle.pathForResource "channelList", ofType:"plist"
		@data = NSArray.arrayWithContentsOfFile channel_plist_path
    outline.expandItem(@data[0])
    # Starting channel
    defaults = NSUserDefaults.standardUserDefaults
    last_channel = defaults.objectForKey(LAST_CHANNEL_KEY)
    puts last_channel.inspect
    stream_channel(last_channel || "NRJ Pure")
  end
  
	def sourceList source_list, shouldSelectItem:item		
		return false if item.kind_of?(Hash)
		true
	end
	
	def sourceList source_list, numberOfChildrenOfItem:item
    item.nil? ? @data.size  : item[:child].count
	end
	
	def sourceList source_list, child:index, ofItem:item
    return nil if @data.nil?
    return @data[index] if item.nil?
    return item[:child][index].keys.first
	end
	
	def sourceList source_list, objectValueForItem:item
		item.kind_of?(Hash) ? item[:group] : item
	end
	
	def sourceList source_list, selectionIndexesForProposedSelection:selected_indexes
		item = outline.itemAtRow(selected_indexes.firstIndex)
    stream_channel(item)
		selected_indexes
	end
	
	def sourceList source_list, isItemExpandable:item
		item.kind_of?(Hash)
	end
	
	def sourceList source_list, itemHasBadge:item
		item.kind_of?(Hash)
	end
	
	def sourceList source_list, badgeValueForItem:item
		item[:child].count
	end
	
	def sourceList source_list, itemHasIcon:item
		!item.kind_of?(Hash)
	end
	
	def sourceList source_list, iconForItem:item
		NSImage.imageNamed "NSSlideshowTemplate"
	end
	
	# selection changed
	def sourceListSelectionDidChange notification
		@remove_progress[] if @remove_progress
		selected_indexes = outline.selectedRowIndexes
		if(selected_indexes.count > 1)
			# NSLog("multiple selected")
		elsif(selected_indexes.count == 1)
			row = selected_indexes.firstIndex
			identifier = outline.itemAtRow(row)
			view = selected_row_spinner(row)
			outline.addSubview view
			@remove_progress =-> {view.stopAnimation nil; view.removeFromSuperview}
		else
			# NSLog("none selected")
		end
	end

	def selected_row_spinner row
		cell_frame =  outline.frameOfCellAtColumn(0, row:row)
		cell_frame.origin.x -= 40
		indicator = NSProgressIndicator.alloc.initWithFrame(cell_frame)
		indicator.indeterminate = true
		indicator.style = NSProgressIndicatorSpinningStyle
		indicator.controlSize = NSSmallControlSize
		indicator.usesThreadedAnimation = true
		indicator.displayedWhenStopped = false
		indicator.sizeToFit
		indicator.startAnimation nil
		indicator
	end
	
  def stream_channel(item)
    unless @last_item == item
      channel = @data.each do |cat| 
        match = cat[:child].detect{|(name, url)| name.keys.first == item}
        break match if match
      end
      return unless channel && channel.respond_to?(:values)
      @selected_channel = channel.keys.first
      value = channel.values.first
      url = NSURL.URLWithString(value)
      # puts "Changing channel"
      error = Pointer.new("@")
      movie = QTMovie.movieWithAttributes({QTMovieOpenForPlaybackAttribute => true, QTMovieURLAttribute => url}, error)
      NSNotificationCenter.defaultCenter.addObserver( self, 
                                            selector: 'movie_load_state_changed:', 
                                                name: QTMovieLoadStateDidChangeNotification, 
                                              object: movie)
      @last_item = item
    end
  end
		
  def movie_load_state_changed a_notification
    movie = a_notification.object
    load_state = movie.attributeForKey QTMovieLoadStateAttribute
    if load_state == QTMovieLoadStateError
      error = movie.attributeForKey QTMovieLoadStateErrorAttribute
      NSLog("Error: #{error.localizedDescription}")
    end 
    if load_state >= QTMovieLoadStateLoaded
      player.hidden = true unless @player.movie
      movie.autoplay
      player.hidden = false
			@remove_progress[] if @remove_progress
      player.movie = movie
    end
  end	
				
  def will_enter_fullscreen(notification)
    # about to enter Lion's FS mode, collapsing the channel list panel
    @channel_panel_old_size = [split_view.subviews[0].frame[0].x, 
		                          split_view.subviews[0].frame[0].y, 
				                      330, #split_view.subviews[0].frame[1].width
				                      split_view.subviews[0].frame[1].height]
    split_view.subviews[0].frame = [0, 0, 0, split_view.subviews[0].frame[1].height]    
  end
    
  def will_exit_fullscreen(notification)
    # resizing the channel panel
    split_view.subviews[0].frame = @channel_panel_old_size if @channel_panel_old_size
  end
		
  # Leopard fullscreen
  def toggle_fullscreen(sender)
    leo_fullscreen_button.setNextState if sender.nil?		
    is_fullscreen ?  exit_fullscreen : enter_fullscreen
  end
				
  def enter_fullscreen
    will_enter_fullscreen(nil)					
    @is_fullscreen = true

    mFullscreenScreen = window.screen
    screenRect = mFullscreenScreen.frame
    # Create a Window to Cover the screen
    fullscreenWindow = FullScreenWindow.alloc.initWithContentRect screenRect,
                                                      styleMask:NSBorderlessWindowMask,
                                                      backing:NSBackingStoreBuffered,
                                                      defer:false
						
    fullscreenWindow.backgroundColor = NSColor.blackColor
    # Create Window Controllers for fullscreen window and Control Overlay
    @fullscreen_window_controller = NSWindowController.alloc.initWithWindow(fullscreenWindow)
    @fullscreen_overlay_window_controller = FullScreenOverlayWindowController.alloc.init
    fullscreenWindow.addChildWindow(@fullscreen_overlay_window_controller.window, ordered:NSWindowAbove)

    self.repositionOverlayWindow
						
    # Move the Content into fullscreen
    split_view.removeFromSuperviewWithoutNeedingDisplay
    fullscreenWindow.contentView.addSubview(split_view)
    @mSavedMovieViewRect = split_view.frame # remember the current rect/size
    split_view.frame = fullscreenWindow.contentView.bounds

				
    # Bring the fullscreen and overlay windows to the front
    window.orderOut self
    @fullscreen_overlay_window_controller.showWindow self
    @fullscreen_window_controller.showWindow self
						
    # Hide the dock and menu bar, saving previous presentation options
    @saved_presentation_options = NSApp.presentationOptions
    NSApp.setPresentationOptions (NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar)
  end		
				
  def exit_fullscreen
    will_exit_fullscreen(nil)
    @is_fullscreen = false
    
    # player view back to the main window
    split_view.removeFromSuperviewWithoutNeedingDisplay
    split_view.frame = @mSavedMovieViewRect
    window.contentView.addSubview @split_view
    
    # Get rid of the fullscreen windows
    @fullscreen_window_controller.close
    @fullscreen_window_controller = nil
    @fullscreen_overlay_window_controller.close
    @fullscreen_overlay_window_controller = nil
    		
    # Bring the main window back to the front
    window.makeKeyAndOrderFront(self)				
    
    # Restore previous presentation options
    NSApp.presentationOptions = @saved_presentation_options
    
    # resizing the channel panel
    split_view.subviews[0].frame = @channel_panel_old_size if @channel_panel_old_size
  end
				
  def repositionOverlayWindow
    fullscreenRect = @fullscreen_window_controller.window.frame
    overlayWindow = @fullscreen_overlay_window_controller.window
    overlayRect = overlayWindow.frame
    overlayWindow.setFrameOrigin NSMakePoint(NSMinX(fullscreenRect) + ((0.5 * NSWidth(fullscreenRect)) - (0.5 * NSWidth(overlayRect))), 0.15 * NSHeight(fullscreenRect))
  end
  
  def save_last_channel
    defaults = NSUserDefaults.standardUserDefaults
    defaults.setObject(@selected_channel, forKey: LAST_CHANNEL_KEY)
    defaults.synchronize
  end

  def windowWillClose(sender); save_last_channel; exit(1); end
  
  def applicationWillTerminate(notification)
    save_last_channel
  end
  
	# NSSplitterView delegate method => size configuration
	def splitView splitView, constrainMaxCoordinate:proposed_max, ofSubviewAt:divider_index
		300.0
	end
end

