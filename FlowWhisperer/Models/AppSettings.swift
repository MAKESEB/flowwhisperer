import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @Published var openAIKey: String = "" {
        didSet {
            saveToKeychain()
            validateAPIKey()
        }
    }
    
    @Published var isAPIKeyValid: Bool = false
    @Published var isAPIKeySet: Bool = false
    
    @Published var keyboardShortcut: KeyCombination = .defaultShortcut {
        didSet {
            UserDefaults.standard.set(keyboardShortcut.rawValue, forKey: "keyboardShortcut")
        }
    }
    
    @Published var contextPrompt: String = "Please enhance and improve this transcribed text while maintaining its original meaning and intent." {
        didSet {
            UserDefaults.standard.set(contextPrompt, forKey: "contextPrompt")
        }
    }
    
    @Published var isRecording: Bool = false
    @Published var lastTranscription: String = ""
    @Published var isProcessing: Bool = false
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load from Keychain
        if let apiKey = KeychainHelper.standard.read(service: "FlowWhisperer", account: "openai_key") {
            self.openAIKey = String(data: apiKey, encoding: .utf8) ?? ""
            validateAPIKey()
        }
        
        // Load from UserDefaults
        if let shortcutRaw = UserDefaults.standard.string(forKey: "keyboardShortcut"),
           let shortcut = KeyCombination(rawValue: shortcutRaw) {
            self.keyboardShortcut = shortcut
        }
        
        if let context = UserDefaults.standard.string(forKey: "contextPrompt") {
            self.contextPrompt = context
        }
    }
    
    private func saveToKeychain() {
        let keyData = Data(openAIKey.utf8)
        KeychainHelper.standard.save(keyData, service: "FlowWhisperer", account: "openai_key")
    }
    
    private func validateAPIKey() {
        isAPIKeySet = !openAIKey.isEmpty
        guard !openAIKey.isEmpty else {
            isAPIKeyValid = false
            return
        }
        
        Task {
            do {
                let isValid = try await testAPIKey(openAIKey)
                DispatchQueue.main.async {
                    self.isAPIKeyValid = isValid
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAPIKeyValid = false
                }
            }
        }
    }
    
    private func testAPIKey(_ apiKey: String) async throws -> Bool {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                ["role": "user", "content": "Hello world! What date is today?"]
            ],
            "max_tokens": 50
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        
        return false
    }
    
    func clearAPIKey() {
        openAIKey = ""
        isAPIKeyValid = false
        isAPIKeySet = false
        KeychainHelper.standard.delete(service: "FlowWhisperer", account: "openai_key")
    }
    
    func resetToDefaults() {
        openAIKey = ""
        keyboardShortcut = .defaultShortcut
        contextPrompt = "Please enhance and improve this transcribed text while maintaining its original meaning and intent."
        KeychainHelper.standard.delete(service: "FlowWhisperer", account: "openai_key")
    }
}

struct KeyCombination: Codable, Equatable {
    var modifiers: [String]
    var key: String
    
    static let defaultShortcut = KeyCombination(modifiers: ["shift", "cmd"], key: "")
    
    // Predefined shortcut options
    static let presetShortcuts: [KeyCombination] = [
        KeyCombination(modifiers: ["shift", "cmd"], key: ""),
        KeyCombination(modifiers: ["option", "cmd"], key: ""),
        KeyCombination(modifiers: ["ctrl", "cmd"], key: "")
    ]
    
    var displayString: String {
        let modifierSymbols = modifiers.map { modifier in
            switch modifier {
            case "cmd": return "⌘"
            case "option": return "⌥" 
            case "ctrl": return "⌃"
            case "shift": return "⇧"
            case "fn": return "fn"
            default: return modifier
            }
        }
        if key.isEmpty {
            return modifierSymbols.joined(separator: " + ")
        } else {
            return (modifierSymbols + [key.uppercased()]).joined(separator: " + ")
        }
    }
    
    var rawValue: String {
        let data = try? JSONEncoder().encode(self)
        return data?.base64EncodedString() ?? ""
    }
    
    init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue),
              let decoded = try? JSONDecoder().decode(KeyCombination.self, from: data) else {
            return nil
        }
        self = decoded
    }
    
    init(modifiers: [String], key: String) {
        self.modifiers = modifiers
        self.key = key
    }
}