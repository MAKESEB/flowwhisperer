import SwiftUI
import AVFoundation

@main
struct FlowWhispererApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var recordingService = AudioRecordingService()
    @StateObject private var keyboardService = KeyboardService()
    @StateObject private var aiService = AIService()
    
    // Static reference to keep floating window alive
    private static var floatingWindow: NSWindow?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .environmentObject(recordingService)
                .environmentObject(keyboardService) 
                .environmentObject(aiService)
                .frame(minWidth: 500, maxWidth: 600, minHeight: 400, maxHeight: 500)
                .onAppear {
                    // Create floating indicator after main window appears
                    setupFloatingIndicator()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra("FlowWhisperer", systemImage: "mic.fill") {
            StatusMenuView()
                .environmentObject(appSettings)
                .environmentObject(recordingService)
                .environmentObject(keyboardService)
                .environmentObject(aiService)
        }
        .menuBarExtraStyle(.window)
    }
    
    init() {
        print("🚀 DEBUG: FlowWhispererApp init() called")
        requestMicrophonePermission()
    }
    
    private func requestMicrophonePermission() {
        // macOS uses a different approach for microphone permissions
        // The system will automatically prompt when AVAudioRecorder is first used
        print("🎤 DEBUG: Microphone permission will be requested when recording starts")
        
        // Try to setup keyboard service after a delay to ensure all objects are initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔧 DEBUG: Attempting delayed keyboard service setup")
            self.keyboardService.setup(with: self.appSettings, recordingService: self.recordingService, aiService: self.aiService)
        }
    }
    
    private func setupFloatingIndicator() {
        // Don't create if already exists
        if FlowWhispererApp.floatingWindow != nil { return }
        
        print("🔵 DEBUG: Setting up floating indicator...")
        
        if appSettings.showFloatingIndicator {
            let window = FloatingIndicatorWindow()
            
            // Create the indicator view with the SAME environment objects as the main app
            let indicatorView = RecordingIndicatorView()
                .environmentObject(appSettings)  // Use the same instance!
            
            window.contentView = NSHostingView(rootView: indicatorView)
            window.orderFront(nil)
            
            // Keep strong reference
            FlowWhispererApp.floatingWindow = window
            
            print("🔵 DEBUG: Floating indicator window created and displayed")
            print("🔵 DEBUG: Initial indicator state: \(appSettings.indicatorState)")
        }
    }
}