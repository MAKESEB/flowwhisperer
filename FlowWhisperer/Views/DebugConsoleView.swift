import SwiftUI

class DebugLogger: ObservableObject {
    @Published var logs: [DebugLog] = []
    
    static let shared = DebugLogger()
    
    private init() {}
    
    func log(_ message: String, type: LogType = .info) {
        DispatchQueue.main.async {
            let log = DebugLog(
                timestamp: Date(),
                message: message,
                type: type
            )
            self.logs.append(log)
            
            // Keep only last 100 logs to prevent memory issues
            if self.logs.count > 100 {
                self.logs.removeFirst(self.logs.count - 100)
            }
            
            // Also print to console
            print("🔍 DEBUG: \(message)")
        }
    }
    
    func clear() {
        logs.removeAll()
    }
}

struct DebugLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

enum LogType {
    case info, warning, error, success
    
    var color: Color {
        switch self {
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .success: return "checkmark.circle"
        }
    }
}

struct DebugConsoleView: View {
    @StateObject private var logger = DebugLogger.shared
    @State private var autoScroll = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(.accentColor)
                Text("Debug Console")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear") {
                    logger.clear()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logger.logs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                // Timestamp
                                Text(log.formattedTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                
                                // Icon
                                Image(systemName: log.type.icon)
                                    .foregroundColor(log.type.color)
                                    .frame(width: 16)
                                
                                // Message
                                Text(log.message)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(log.type.color)
                                    .textSelection(.enabled)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                            .id(log.id)
                        }
                    }
                }
                .onChange(of: logger.logs.count) { _ in
                    if autoScroll, let lastLog = logger.logs.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer controls
            HStack {
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(SwitchToggleStyle())
                
                Spacer()
                
                Text("\(logger.logs.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            logger.log("Debug console opened", type: .info)
        }
    }
}

struct DebugConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        DebugConsoleView()
    }
}