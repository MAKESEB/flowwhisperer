import SwiftUI
import AVFoundation

@main
struct FlowWhispererApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var recordingService = AudioRecordingService()
    @StateObject private var keyboardService = KeyboardService()
    @StateObject private var openAIService = OpenAIService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .environmentObject(recordingService)
                .environmentObject(keyboardService) 
                .environmentObject(openAIService)
                .frame(minWidth: 500, maxWidth: 600, minHeight: 400, maxHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra("FlowWhisperer", systemImage: "mic.fill") {
            StatusMenuView()
                .environmentObject(appSettings)
                .environmentObject(recordingService)
                .environmentObject(keyboardService)
                .environmentObject(openAIService)
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
            self.keyboardService.setup(with: self.appSettings, recordingService: self.recordingService, openAIService: self.openAIService)
        }
    }
}