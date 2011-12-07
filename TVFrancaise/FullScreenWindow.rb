#
#  FullScreenWindow.rb
#  LiveTV
#
#  Created by Mateus on 30.11.11.
#  Copyright 2011
#
class FullScreenWindow < NSWindow
		attr_accessor :view
  def canBecomeKeyWindow; true; end
  
		# ESC key or Cmd-period while in fullscreen mode
  def cancelOperation sender
    target = NSApp.targetForAction "toggle_fullscreen:", to:nil, from:nil
				target.performSelector "toggle_fullscreen:", withObject:nil
  end
end



