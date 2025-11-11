import Foundation
import AppKit

class ClipboardHelper {
    static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        print("Copied to clipboard: \(text.prefix(50))\(text.count > 50 ? "..." : "")")
    }
    
    static func getClipboardContent() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    static func clearClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
    }
}