import SwiftUI
import AppKit

class FloatingIndicatorWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 40, height: 40),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Make window always on top
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Position in bottom-right corner
        positionWindow()
        
        // Content view will be set externally with proper environment
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = self.frame.size
        
        // Position with 50px padding from bottom-right
        let x = screenFrame.maxX - windowSize.width - 50
        let y = screenFrame.minY + 50
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func updatePosition() {
        positionWindow()
    }
}