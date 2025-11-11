import Foundation
import SwiftUI

class OpenAIService: ObservableObject {
    private let baseURL = "https://api.openai.com/v1"
    
    @Published var isProcessing = false
    
    // MARK: - Transcription
    
    func transcribeAudio(_ audioURL: URL, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("gpt-4o-transcribe\r\n".data(using: .utf8)!)
        
        // Add file parameter
        do {
            let audioData = try Data(contentsOf: audioURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            throw OpenAIError.fileError(error.localizedDescription)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Transcription API Error: \(errorText)")
            throw OpenAIError.apiError(httpResponse.statusCode, errorText)
        }
        
        do {
            let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            return transcriptionResponse.text
        } catch {
            print("Failed to decode transcription response: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw OpenAIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Text Enhancement
    
    func enhanceText(_ text: String, context: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = [
            ChatMessage(role: "system", content: """
            You are a text enhancement assistant. Your task is to improve transcribed speech while maintaining its original meaning and intent.
            
            User's context: \(context)
            
            Instructions:
            1. Fix grammar, punctuation, and spelling errors
            2. Improve clarity and readability
            3. Maintain the original tone and meaning
            4. Return only the enhanced text as a JSON object with a "enhanced_text" field
            """),
            ChatMessage(role: "user", content: "Please enhance this transcribed text: \"\(text)\"")
        ]
        
        let requestBody = ChatCompletionRequest(
            model: "gpt-5-mini",
            messages: messages,
            responseFormat: ResponseFormat(type: "json_object")
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw OpenAIError.encodingError(error.localizedDescription)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Enhancement API Error: \(errorText)")
            throw OpenAIError.apiError(httpResponse.statusCode, errorText)
        }
        
        do {
            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            
            guard let messageContent = chatResponse.choices.first?.message.content else {
                throw OpenAIError.noResponse
            }
            
            // Parse the JSON response to extract enhanced text
            if let jsonData = messageContent.data(using: .utf8),
               let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let enhancedText = jsonObject["enhanced_text"] as? String {
                return enhancedText
            } else {
                // Fallback: return the content directly if JSON parsing fails
                return messageContent
            }
            
        } catch {
            print("Failed to decode enhancement response: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw OpenAIError.decodingError(error.localizedDescription)
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
        
        // Step 1: Transcribe audio
        let transcribedText = try await transcribeAudio(audioURL, apiKey: apiKey)
        print("Transcribed text: \(transcribedText)")
        
        // Step 2: Enhance text
        let enhancedText = try await enhanceText(transcribedText, context: context, apiKey: apiKey)
        print("Enhanced text: \(enhancedText)")
        
        return enhancedText
    }
}

// MARK: - Data Models

struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ResponseFormat: Codable {
    let type: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case responseFormat = "response_format"
    }
}

struct ChatCompletionResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

// MARK: - Error Types

enum OpenAIError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(Int, String)
    case fileError(String)
    case encodingError(String)
    case decodingError(String)
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .fileError(let error):
            return "File error: \(error)"
        case .encodingError(let error):
            return "Encoding error: \(error)"
        case .decodingError(let error):
            return "Decoding error: \(error)"
        case .noResponse:
            return "No response received from API"
        }
    }
}