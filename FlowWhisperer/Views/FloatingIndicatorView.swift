import SwiftUI

struct FloatingIndicatorView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        RecordingIndicatorView()
            .environmentObject(appSettings)
            .frame(width: 40, height: 40)
            .background(Color.clear)
            .onAppear {
                print("🔵 DEBUG: FloatingIndicatorView appeared")
                appSettings.indicatorState = .idle
                
                // Make this window float and ignore events
                if let window = NSApplication.shared.windows.last {
                    window.level = .floating
                    window.isOpaque = false
                    window.backgroundColor = NSColor.clear
                    window.hasShadow = false
                    window.ignoresMouseEvents = true
                    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                    print("🔵 DEBUG: Window configured for floating overlay")
                }
            }
    }
}