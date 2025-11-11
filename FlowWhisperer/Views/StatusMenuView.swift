import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var recordingService: AudioRecordingService
    @EnvironmentObject var keyboardService: KeyboardService
    @EnvironmentObject var openAIService: OpenAIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.accentColor)
                    
                    Text("FlowWhisperer")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    StatusIndicator(
                        isRecording: appSettings.isRecording,
                        isProcessing: appSettings.isProcessing,
                        hasAPIKey: !appSettings.openAIKey.isEmpty
                    )
                }
                
                Text("Shortcut: \(appSettings.keyboardShortcut.displayString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Last transcription (if available)
            if !appSettings.lastTranscription.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Result")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(appSettings.lastTranscription)
                        .font(.caption)
                        .lineLimit(3)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider()
            }
            
            // Action buttons
            VStack(spacing: 0) {
                MenuButton(
                    title: "Open Settings",
                    systemImage: "gearshape",
                    action: openMainWindow
                )
                
                MenuButton(
                    title: "Test Recording",
                    systemImage: "mic.badge.plus",
                    action: testRecording,
                    disabled: appSettings.openAIKey.isEmpty || !recordingService.hasPermission
                )
                
                Divider()
                
                MenuButton(
                    title: "Open Privacy Settings",
                    systemImage: "lock.shield",
                    action: openPrivacySettings
                )
                
                Divider()
                
                MenuButton(
                    title: "Quit FlowWhisperer",
                    systemImage: "power",
                    action: quit,
                    destructive: true
                )
            }
        }
        .frame(width: 280)
        .onAppear {
            print("📱 DEBUG: StatusMenuView onAppear called")
            // Setup keyboard service when menu bar appears
            keyboardService.setup(with: appSettings, recordingService: recordingService, openAIService: openAIService)
        }
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.title.contains("FlowWhisperer") || window.contentView is NSHostingView<ContentView> {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        
        // If no window found, create one
        let contentView = ContentView()
            .environmentObject(appSettings)
            .environmentObject(recordingService)
            .environmentObject(keyboardService)
            .environmentObject(openAIService)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FlowWhisperer Settings"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    private func testRecording() {
        // Simple test - just show notification
        NotificationHelper.showNotification(
            title: "FlowWhisperer Test",
            body: "Press \(appSettings.keyboardShortcut.displayString) to start recording",
            sound: .default
        )
    }
    
    private func openPrivacySettings() {
        recordingService.openSystemPreferences()
    }
    
    private func quit() {
        NSApp.terminate(nil)
    }
}

struct StatusIndicator: View {
    let isRecording: Bool
    let isProcessing: Bool
    let hasAPIKey: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        if isRecording {
            return .red
        } else if isProcessing {
            return .orange
        } else if !hasAPIKey {
            return .yellow
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if isRecording {
            return "Recording"
        } else if isProcessing {
            return "Processing"
        } else if !hasAPIKey {
            return "Setup"
        } else {
            return "Ready"
        }
    }
}

struct MenuButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var disabled: Bool = false
    var destructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .frame(width: 16)
                    .foregroundColor(destructive ? .red : .accentColor)
                
                Text(title)
                    .foregroundColor(destructive ? .red : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
        .onHover { hovering in
            if hovering && !disabled {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}