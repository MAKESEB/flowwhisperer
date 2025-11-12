// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlowWhisperer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "FlowWhisperer", targets: ["FlowWhisperer"])
    ],
    targets: [
        .executableTarget(
            name: "FlowWhisperer",
            path: "FlowWhisperer",
            sources: [
                "FlowWhispererApp.swift",
                "Views/ContentView.swift",
                "Views/SettingsView.swift", 
                "Views/KeyboardShortcutPicker.swift",
                "Views/StatusMenuView.swift",
                "Views/FloatingIndicatorWindow.swift",
                "Views/RecordingIndicatorView.swift",
                "Views/FloatingIndicatorView.swift",
                "Models/AppSettings.swift",
                "Models/APIProvider.swift",
                "Services/AudioRecordingService.swift",
                "Services/AIService.swift", 
                "Services/KeyboardService.swift",
                "Utils/KeychainHelper.swift",
                "Utils/ClipboardHelper.swift",
                "Utils/NotificationHelper.swift"
            ]
        )
    ]
)