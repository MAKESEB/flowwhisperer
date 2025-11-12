import Foundation
import SwiftUI

class AIService: ObservableObject {
    private var currentProvider: APIProvider = .openai
    private var providerConfig: ProviderConfig = OpenAIConfig()
    
    @Published var isProcessing = false
    
    func setProvider(_ provider: APIProvider) {
        self.currentProvider = provider
        self.providerConfig = ProviderConfigFactory.create(provider)
        print("🤖 DEBUG: Switched to \(provider.displayName) provider")
    }
    
    // MARK: - Transcription
    
    func transcribeAudio(_ audioURL: URL, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        print("🤖 DEBUG: Transcribing audio using \(currentProvider.displayName) (\(providerConfig.transcriptionModel))")
        
        // Handle Google's special transcription process
        if currentProvider == .google, let googleConfig = providerConfig as? GoogleConfig {
            // Google requires file upload first, then transcription
            let fileURI = try await googleConfig.uploadFileForTranscription(audioURL: audioURL, apiKey: apiKey)
            print("🤖 DEBUG: Google file uploaded with URI: \(fileURI)")
            
            let transcribedText = try await googleConfig.transcribeWithFileURI(fileURI, apiKey: apiKey)
            print("🤖 DEBUG: Successfully transcribed \(transcribedText.count) characters using \(currentProvider.displayName)")
            return transcribedText
        }
        
        // Standard transcription for OpenAI and Groq
        let request = try providerConfig.transcriptionRequest(audioURL: audioURL, apiKey: apiKey)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🤖 DEBUG: Transcription API Error (\(currentProvider.displayName)): \(errorText)")
            throw APIError.apiError(httpResponse.statusCode, errorText)
        }
        
        do {
            let transcribedText = try providerConfig.parseTranscriptionResponse(data: data)
            print("🤖 DEBUG: Successfully transcribed \(transcribedText.count) characters using \(currentProvider.displayName)")
            return transcribedText
        } catch {
            print("🤖 DEBUG: Failed to parse transcription response from \(currentProvider.displayName): \(error)")
            print("🤖 DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Text Enhancement
    
    func enhanceText(_ text: String, context: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        print("🤖 DEBUG: Enhancing text using \(currentProvider.displayName) (\(providerConfig.enhancementModel))")
        
        let request = try providerConfig.enhancementRequest(text: text, context: context, apiKey: apiKey)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🤖 DEBUG: Enhancement API Error (\(currentProvider.displayName)): \(errorText)")
            throw APIError.apiError(httpResponse.statusCode, errorText)
        }
        
        do {
            let enhancedText = try providerConfig.parseEnhancementResponse(data: data)
            let cleanedText = stripQuotes(from: enhancedText)
            print("🤖 DEBUG: Successfully enhanced text using \(currentProvider.displayName)")
            return cleanedText
        } catch {
            print("🤖 DEBUG: Failed to parse enhancement response from \(currentProvider.displayName): \(error)")
            print("🤖 DEBUG: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Combined Process
    
    func processAudio(_ audioURL: URL, context: String, apiKey: String) async throws -> String {
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        print("🤖 DEBUG: Processing audio using \(currentProvider.displayName)")
        
        // Step 1: Transcribe audio
        let transcribedText = try await transcribeAudio(audioURL, apiKey: apiKey)
        print("🤖 DEBUG: Transcribed text (\(transcribedText.count) chars): \(transcribedText.prefix(100))...")
        
        // Step 2: Enhance text
        let enhancedText = try await enhanceText(transcribedText, context: context, apiKey: apiKey)
        print("🤖 DEBUG: Enhanced text (\(enhancedText.count) chars): \(enhancedText.prefix(100))...")
        
        return enhancedText
    }
    
    // MARK: - Text Cleanup
    
    private func stripQuotes(from text: String) -> String {
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove quotes from beginning and end
        let quotesToRemove = ["\"", "'", "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}"]
        
        for quote in quotesToRemove {
            if cleanedText.hasPrefix(quote) && cleanedText.hasSuffix(quote) && cleanedText.count > 2 {
                cleanedText = String(cleanedText.dropFirst().dropLast())
                cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return cleanedText
    }
}