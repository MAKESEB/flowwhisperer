import Foundation
import SwiftUI

enum IndicatorState {
    case hidden
    case idle
    case recording
    case processing
    case success
}

class AppSettings: ObservableObject {
    // API Provider Selection
    @Published var selectedProvider: APIProvider = .openai {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selectedProvider")
            validateCurrentAPIKey()
        }
    }
    
    // API Keys for each provider
    @Published var openAIKey: String = "" {
        didSet {
            UserDefaults.standard.set(openAIKey, forKey: "openai_api_key")
            if selectedProvider == .openai {
                validateCurrentAPIKey()
            }
        }
    }
    
    @Published var groqKey: String = "" {
        didSet {
            UserDefaults.standard.set(groqKey, forKey: "groq_api_key")
            if selectedProvider == .groq {
                validateCurrentAPIKey()
            }
        }
    }
    
    @Published var googleKey: String = "" {
        didSet {
            UserDefaults.standard.set(googleKey, forKey: "google_api_key")
            if selectedProvider == .google {
                validateCurrentAPIKey()
            }
        }
    }
    
    // Current API key based on selected provider
    var currentAPIKey: String {
        switch selectedProvider {
        case .openai: return openAIKey
        case .groq: return groqKey
        case .google: return googleKey
        }
    }
    
    // Validation states for each provider
    @Published var isOpenAIKeyValid: Bool = false
    @Published var isGroqKeyValid: Bool = false
    @Published var isGoogleKeyValid: Bool = false
    @Published var isValidatingAPIKey: Bool = false
    
    // Current provider validation state
    var isCurrentAPIKeyValid: Bool {
        switch selectedProvider {
        case .openai: return isOpenAIKeyValid
        case .groq: return isGroqKeyValid
        case .google: return isGoogleKeyValid
        }
    }
    
    var isCurrentAPIKeySet: Bool {
        return !currentAPIKey.isEmpty
    }
    
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
    
    // Floating indicator state
    @Published var indicatorState: IndicatorState = .idle {
        didSet {
            print("🔵 DEBUG: AppSettings.indicatorState changed from \(oldValue) to \(indicatorState)")
        }
    }
    @Published var showFloatingIndicator: Bool = true
    
    private var validationTask: Task<Void, Never>?
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load selected provider
        if let providerRaw = UserDefaults.standard.string(forKey: "selectedProvider"),
           let provider = APIProvider(rawValue: providerRaw) {
            self.selectedProvider = provider
        }
        
        // Load API keys from UserDefaults
        if let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") {
            self.openAIKey = apiKey
        }
        
        if let apiKey = UserDefaults.standard.string(forKey: "groq_api_key") {
            self.groqKey = apiKey
        }
        
        if let apiKey = UserDefaults.standard.string(forKey: "google_api_key") {
            self.googleKey = apiKey
        }
        
        // Load keyboard shortcut
        if let shortcutRaw = UserDefaults.standard.string(forKey: "keyboardShortcut"),
           let shortcut = KeyCombination(rawValue: shortcutRaw) {
            self.keyboardShortcut = shortcut
        }
        
        // Load context prompt
        if let context = UserDefaults.standard.string(forKey: "contextPrompt") {
            self.contextPrompt = context
        }
    }
    
    
    private func validateCurrentAPIKey() {
        let apiKey = currentAPIKey
        let provider = selectedProvider
        
        guard !apiKey.isEmpty else {
            updateValidationState(for: provider, isValid: false, isValidating: false)
            print("🔑 DEBUG: Empty API key for \(provider.displayName), skipping validation")
            return
        }
        
        // Don't start new validation if already validating
        guard !isValidatingAPIKey else { 
            print("🔑 DEBUG: Already validating, skipping")
            return 
        }
        
        print("🔑 DEBUG: Starting \(provider.displayName) API key validation...")
        
        // Set validating state
        isValidatingAPIKey = true
        updateValidationState(for: provider, isValid: false, isValidating: true)
        
        // Simple validation without complex debouncing
        Task {
            do {
                print("🔑 DEBUG: Making \(provider.displayName) API test call...")
                let isValid = try await testAPIKey(apiKey, provider: provider)
                print("🔑 DEBUG: \(provider.displayName) API test call returned: \(isValid)")
                
                await MainActor.run {
                    print("🔑 DEBUG: Updating UI - \(provider.displayName) Valid: \(isValid)")
                    self.updateValidationState(for: provider, isValid: isValid, isValidating: false)
                    self.isValidatingAPIKey = false
                    print("🔑 DEBUG: \(provider.displayName) validation complete")
                }
            } catch {
                print("🔑 DEBUG: \(provider.displayName) API validation error: \(error)")
                await MainActor.run {
                    self.updateValidationState(for: provider, isValid: false, isValidating: false)
                    self.isValidatingAPIKey = false
                    print("🔑 DEBUG: \(provider.displayName) validation failed")
                }
            }
        }
    }
    
    private func updateValidationState(for provider: APIProvider, isValid: Bool, isValidating: Bool) {
        switch provider {
        case .openai:
            self.isOpenAIKeyValid = isValid
        case .groq:
            self.isGroqKeyValid = isValid
        case .google:
            self.isGoogleKeyValid = isValid
        }
    }
    
    private func testAPIKey(_ apiKey: String, provider: APIProvider) async throws -> Bool {
        let config = ProviderConfigFactory.create(provider)
        let request = try config.validationRequest(apiKey: apiKey)
        
        print("🔑 API Key Validation Request to: \(request.url?.absoluteString ?? "unknown")")
        print("🔑 Provider: \(provider.displayName)")
        
        print("🔑 DEBUG: Sending request to \(provider.displayName)...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("🔑 DEBUG: Received response from \(provider.displayName)")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🔑 DEBUG: HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                print("🔑 DEBUG: ✅ \(provider.displayName) API key is valid!")
                return try config.parseValidationResponse(data: data)
            } else {
                if let errorData = String(data: data, encoding: .utf8) {
                    print("🔑 DEBUG: ❌ \(provider.displayName) API Error (\(httpResponse.statusCode)): \(errorData)")
                }
                return false
            }
        }
        
        print("🔑 DEBUG: ❌ No HTTP response received from \(provider.displayName)")
        return false
    }
    
    func clearCurrentAPIKey() {
        switch selectedProvider {
        case .openai:
            openAIKey = ""
            isOpenAIKeyValid = false
            UserDefaults.standard.removeObject(forKey: "openai_api_key")
        case .groq:
            groqKey = ""
            isGroqKeyValid = false
            UserDefaults.standard.removeObject(forKey: "groq_api_key")
        case .google:
            googleKey = ""
            isGoogleKeyValid = false
            UserDefaults.standard.removeObject(forKey: "google_api_key")
        }
    }
    
    func clearAllAPIKeys() {
        openAIKey = ""
        groqKey = ""
        googleKey = ""
        isOpenAIKeyValid = false
        isGroqKeyValid = false
        isGoogleKeyValid = false
        UserDefaults.standard.removeObject(forKey: "openai_api_key")
        UserDefaults.standard.removeObject(forKey: "groq_api_key")
        UserDefaults.standard.removeObject(forKey: "google_api_key")
    }
    
    func resetToDefaults() {
        selectedProvider = .openai
        clearAllAPIKeys()
        keyboardShortcut = .defaultShortcut
        contextPrompt = "Please enhance and improve this transcribed text while maintaining its original meaning and intent."
        UserDefaults.standard.removeObject(forKey: "selectedProvider")
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