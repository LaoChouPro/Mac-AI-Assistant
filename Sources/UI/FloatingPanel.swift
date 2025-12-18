import Cocoa

class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect,
                   styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .closable, .resizable], 
                   backing: .buffered, 
                   defer: false)
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Transparent title bar
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        // Movable by background
        self.isMovableByWindowBackground = true
        
        // Hide standard buttons
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Background settings for glass effect
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
    }
    
    // Allow closing with ESC
    override func cancelOperation(_ sender: Any?) {
        self.close()
    }
    
    // Ensure it can become key even without activation policy
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
