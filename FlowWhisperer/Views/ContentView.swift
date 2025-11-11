import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var recordingService: AudioRecordingService
    @EnvironmentObject var keyboardService: KeyboardService
    @EnvironmentObject var openAIService: OpenAIService
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("FlowWhisperer")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Voice-to-clipboard transcription")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(appSettings.isRecording ? .red : (appSettings.openAIKey.isEmpty ? .orange : .green))
                        .frame(width: 8, height: 8)
                    
                    Text(appSettings.isRecording ? "Recording" : (appSettings.openAIKey.isEmpty ? "Setup Required" : "Ready"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Main content
            SettingsView()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            print("🖥️ DEBUG: ContentView onAppear called")
            keyboardService.setup(with: appSettings, recordingService: recordingService, openAIService: openAIService)
        }
    }
}