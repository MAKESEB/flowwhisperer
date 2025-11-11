import Foundation
import Carbon
import SwiftUI

class KeyboardService: ObservableObject {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var appSettings: AppSettings?
    private var recordingService: AudioRecordingService?
    private var openAIService: OpenAIService?
    private var keyMonitorTimer: Timer?
    private var lastAllPressed = false
    
    private let hotKeySignature = OSType(0x46575354) // 'FWST' for FlowWhisperer
    private let hotKeyID = UInt32(1)
    
    func setup(with appSettings: AppSettings, recordingService: AudioRecordingService, openAIService: OpenAIService) {
        self.appSettings = appSettings
        self.recordingService = recordingService
        self.openAIService = openAIService
        
        print("🔧 DEBUG: KeyboardService setup called")
        print("🔧 DEBUG: Shortcut modifiers: \(appSettings.keyboardShortcut.modifiers)")
        print("🔧 DEBUG: Shortcut key: '\(appSettings.keyboardShortcut.key)'")
        print("🔧 DEBUG: Display string: \(appSettings.keyboardShortcut.displayString)")
        
        registerGlobalShortcut()
    }
    
    private func registerGlobalShortcut() {
        unregisterGlobalShortcut()
        
        guard let appSettings = appSettings else { return }
        
        // All shortcuts are now modifier-only, use monitoring approach
        startModifierKeyMonitoring()
        print("Registered modifier-only shortcut monitoring: \(appSettings.keyboardShortcut.displayString)")
    }
    
    private func unregisterGlobalShortcut() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    
    private func startModifierKeyMonitoring() {
        keyMonitorTimer?.invalidate()
        print("🔍 DEBUG: Starting modifier key monitoring...")
        print("🔍 DEBUG: Required modifiers: \(appSettings?.keyboardShortcut.modifiers ?? [])")
        
        keyMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let appSettings = self.appSettings else { return }
            
            let currentModifiers = GetCurrentKeyModifiers()
            let shortcutModifiers = appSettings.keyboardShortcut.modifiers
            
            // Debug: Show current modifier state every 2 seconds
            let now = Date().timeIntervalSince1970
            if Int(now) % 2 == 0 && Int((now * 20).truncatingRemainder(dividingBy: 1) * 20) == 0 {
                print("🔍 DEBUG: Current modifiers raw value: \(currentModifiers)")
                print("🔍 DEBUG: Required: \(shortcutModifiers), Recording: \(appSettings.isRecording)")
            }
            
            var allPressed = true
            var debugInfo: [String] = []
            
            // Check each required modifier
            for modifier in shortcutModifiers {
                var isPressed = false
                switch modifier.lowercased() {
                case "cmd":
                    isPressed = (currentModifiers & UInt32(cmdKey)) != 0
                    debugInfo.append("cmd: \(isPressed)")
                case "option":
                    isPressed = (currentModifiers & UInt32(optionKey)) != 0
                    debugInfo.append("option: \(isPressed)")
                case "ctrl":
                    isPressed = (currentModifiers & UInt32(controlKey)) != 0
                    debugInfo.append("ctrl: \(isPressed)")
                case "shift":
                    isPressed = (currentModifiers & UInt32(shiftKey)) != 0
                    debugInfo.append("shift: \(isPressed)")
                case "fn":
                    isPressed = (currentModifiers & UInt32(NSEvent.ModifierFlags.function.rawValue >> 16)) != 0
                    debugInfo.append("fn: \(isPressed)")
                default:
                    break
                }
                
                if !isPressed {
                    allPressed = false
                }
            }
            
            // Debug when state changes (using instance variable instead of static)
            if allPressed != self.lastAllPressed {
                print("🔍 DEBUG: Modifier state changed - All pressed: \(allPressed)")
                print("🔍 DEBUG: Individual states: \(debugInfo.joined(separator: ", "))")
                self.lastAllPressed = allPressed
            }
            
            // Start recording if all modifiers pressed and not currently recording
            if allPressed && !appSettings.isRecording {
                print("🎤 DEBUG: Starting recording...")
                self.startRecording()
            } 
            // Stop recording if not all modifiers pressed and currently recording
            else if !allPressed && appSettings.isRecording {
                print("🛑 DEBUG: Stopping recording...")
                self.stopRecording()
            }
        }
    }
    
    private func startKeyMonitoring() {
        keyMonitorTimer?.invalidate()
        keyMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.areKeysPressed() {
                self.stopRecording()
                self.keyMonitorTimer?.invalidate()
                self.keyMonitorTimer = nil
            }
        }
    }
    
    private func areKeysPressed() -> Bool {
        guard let appSettings = appSettings else { return false }
        
        let keyCode = keyCodeFromString(appSettings.keyboardShortcut.key)
        let modifierFlags = modifierFlagsFromStrings(appSettings.keyboardShortcut.modifiers)
        
        // Check if the key is still pressed
        let keyState = GetCurrentKeyModifiers()
        let isKeyPressed = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(keyCode))
        
        // Check modifier keys
        var modifiersPressed = true
        for modifier in appSettings.keyboardShortcut.modifiers {
            switch modifier.lowercased() {
            case "cmd":
                modifiersPressed = modifiersPressed && (keyState & UInt32(cmdKey)) != 0
            case "option":
                modifiersPressed = modifiersPressed && (keyState & UInt32(optionKey)) != 0
            case "ctrl":
                modifiersPressed = modifiersPressed && (keyState & UInt32(controlKey)) != 0
            case "shift":
                modifiersPressed = modifiersPressed && (keyState & UInt32(shiftKey)) != 0
            case "fn":
                // fn key is harder to detect, we'll skip it for now
                break
            default:
                break
            }
        }
        
        return isKeyPressed && modifiersPressed
    }
    
    private func startRecording() {
        print("🎤 DEBUG: startRecording() called")
        
        guard let appSettings = appSettings,
              let recordingService = recordingService else {
            print("❌ DEBUG: Missing dependencies - appSettings: \(appSettings != nil), recordingService: \(recordingService != nil)")
            return
        }
        
        print("🎤 DEBUG: Current recording state: \(appSettings.isRecording)")
        
        // Don't start if already recording
        guard !appSettings.isRecording else { 
            print("⚠️ DEBUG: Already recording, skipping start")
            return 
        }
        
        print("🎤 DEBUG: Calling recordingService.startRecording()...")
        if recordingService.startRecording() {
            appSettings.isRecording = true
            print("✅ DEBUG: Recording started successfully")
            
            NotificationHelper.showNotification(
                title: "FlowWhisperer",
                body: "Recording...",
                sound: nil
            )
        } else {
            print("❌ DEBUG: Failed to start recording")
            NotificationHelper.showNotification(
                title: "FlowWhisperer Error",
                body: "Failed to start recording. Check microphone permissions.",
                sound: .default
            )
        }
    }
    
    private func stopRecording() {
        print("🛑 DEBUG: stopRecording() called")
        
        guard let appSettings = appSettings,
              let recordingService = recordingService,
              let openAIService = openAIService else {
            print("❌ DEBUG: Missing dependencies in stopRecording")
            return
        }
        
        print("🛑 DEBUG: Current recording state: \(appSettings.isRecording)")
        
        // Don't stop if not recording
        guard appSettings.isRecording else { 
            print("⚠️ DEBUG: Not recording, skipping stop")
            return 
        }
        
        print("🛑 DEBUG: Calling recordingService.stopRecording()...")
        if let audioURL = recordingService.stopRecording() {
            appSettings.isRecording = false
            print("✅ DEBUG: Recording stopped, audio file: \(audioURL.path)")
            
            Task {
                do {
                    print("🔄 DEBUG: Processing audio with OpenAI...")
                    let result = try await openAIService.processAudio(
                        audioURL,
                        context: appSettings.contextPrompt,
                        apiKey: appSettings.openAIKey
                    )
                    
                    print("✅ DEBUG: OpenAI processing complete: \(result.prefix(50))...")
                    
                    DispatchQueue.main.async {
                        appSettings.lastTranscription = result
                        ClipboardHelper.copyToClipboard(result)
                        
                        // Show notification
                        NotificationHelper.showNotification(
                            title: "FlowWhisperer",
                            body: "Text copied to clipboard",
                            sound: .default
                        )
                    }
                    
                    // Cleanup audio file
                    try FileManager.default.removeItem(at: audioURL)
                    print("🗑️ DEBUG: Audio file cleaned up")
                    
                } catch {
                    print("❌ DEBUG: Processing error: \(error)")
                    DispatchQueue.main.async {
                        print("Processing error: \(error)")
                        NotificationHelper.showNotification(
                            title: "FlowWhisperer Error",
                            body: error.localizedDescription,
                            sound: .default
                        )
                    }
                }
            }
        } else {
            print("❌ DEBUG: stopRecording returned nil audioURL")
        }
    }
    
    private func keyCodeFromString(_ key: String) -> Int {
        switch key.lowercased() {
        case "a": return kVK_ANSI_A
        case "s": return kVK_ANSI_S
        case "d": return kVK_ANSI_D
        case "f": return kVK_ANSI_F
        case "h": return kVK_ANSI_H
        case "g": return kVK_ANSI_G
        case "z": return kVK_ANSI_Z
        case "x": return kVK_ANSI_X
        case "c": return kVK_ANSI_C
        case "v": return kVK_ANSI_V
        case "b": return kVK_ANSI_B
        case "q": return kVK_ANSI_Q
        case "w": return kVK_ANSI_W
        case "e": return kVK_ANSI_E
        case "r": return kVK_ANSI_R
        case "y": return kVK_ANSI_Y
        case "t": return kVK_ANSI_T
        case "1": return kVK_ANSI_1
        case "2": return kVK_ANSI_2
        case "3": return kVK_ANSI_3
        case "4": return kVK_ANSI_4
        case "6": return kVK_ANSI_6
        case "5": return kVK_ANSI_5
        case "=": return kVK_ANSI_Equal
        case "9": return kVK_ANSI_9
        case "7": return kVK_ANSI_7
        case "-": return kVK_ANSI_Minus
        case "8": return kVK_ANSI_8
        case "0": return kVK_ANSI_0
        case "]": return kVK_ANSI_RightBracket
        case "o": return kVK_ANSI_O
        case "u": return kVK_ANSI_U
        case "[": return kVK_ANSI_LeftBracket
        case "i": return kVK_ANSI_I
        case "p": return kVK_ANSI_P
        case "l": return kVK_ANSI_L
        case "j": return kVK_ANSI_J
        case "'": return kVK_ANSI_Quote
        case "k": return kVK_ANSI_K
        case ";": return kVK_ANSI_Semicolon
        case "\\": return kVK_ANSI_Backslash
        case ",": return kVK_ANSI_Comma
        case "/": return kVK_ANSI_Slash
        case "n": return kVK_ANSI_N
        case "m": return kVK_ANSI_M
        case ".": return kVK_ANSI_Period
        case "`": return kVK_ANSI_Grave
        default: return kVK_ANSI_W // Default to W
        }
    }
    
    private func modifierFlagsFromStrings(_ modifiers: [String]) -> UInt32 {
        var flags: UInt32 = 0
        
        for modifier in modifiers {
            switch modifier.lowercased() {
            case "cmd":
                flags |= UInt32(cmdKey)
            case "option":
                flags |= UInt32(optionKey)
            case "ctrl":
                flags |= UInt32(controlKey)
            case "shift":
                flags |= UInt32(shiftKey)
            case "fn":
                flags |= UInt32(NSEvent.ModifierFlags.function.rawValue >> 16)
            default:
                break
            }
        }
        
        return flags
    }
    
    deinit {
        keyMonitorTimer?.invalidate()
        unregisterGlobalShortcut()
    }
}