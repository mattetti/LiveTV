#
#  FullScreenOverlayWindowController.rb
#  LiveTV
#
#  Created by Mateus on 30.11.11.
#  Copyright 2011
#

class FullScreenOverlayWindowController < NSWindowController
		def init
				self.initWithWindowNibName "FullScreenOverlayWindow"
		end
		
		def windowDidLoad
				super
				window = self.window
				window.setStyleMask NSBorderlessWindowMask
				window.setAlphaValue 1.0
				window.setMovableByWindowBackground true  	
		end
end


