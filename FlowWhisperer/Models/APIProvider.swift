import Foundation

// MARK: - API Provider Types

enum APIProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case groq = "Groq"
    
    var displayName: String {
        return rawValue
    }
    
    var baseURL: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1"
        case .groq:
            return "https://api.groq.com/openai/v1"
        }
    }
}

// MARK: - Provider Configuration Protocol

protocol ProviderConfig {
    var provider: APIProvider { get }
    var baseURL: String { get }
    var transcriptionModel: String { get }
    var enhancementModel: String { get }
    var validationModel: String { get }
    
    func transcriptionRequest(audioURL: URL, apiKey: String) throws -> URLRequest
    func enhancementRequest(text: String, context: String, apiKey: String) throws -> URLRequest
    func validationRequest(apiKey: String) throws -> URLRequest
    func parseTranscriptionResponse(data: Data) throws -> String
    func parseEnhancementResponse(data: Data) throws -> String
    func parseValidationResponse(data: Data) throws -> Bool
}

// MARK: - OpenAI Configuration

struct OpenAIConfig: ProviderConfig {
    let provider: APIProvider = .openai
    let baseURL: String = "https://api.openai.com/v1"
    let transcriptionModel: String = "gpt-4o-transcribe"
    let enhancementModel: String = "gpt-5-mini"
    let validationModel: String = "gpt-5-nano"
    
    func transcriptionRequest(audioURL: URL, apiKey: String) throws -> URLRequest {
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
        body.append("\(transcriptionModel)\r\n".data(using: .utf8)!)
        
        // Add file parameter
        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        return request
    }
    
    func enhancementRequest(text: String, context: String, apiKey: String) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = [
            ["role": "system", "content": """
            You are a text enhancement assistant. Your task is to improve transcribed speech while maintaining its original meaning and intent.
            
            User's context: \(context)
            
            Instructions:
            1. Fix grammar, punctuation, and spelling errors
            2. Improve clarity and readability
            3. Maintain the original tone and meaning
            4. You must return your response as a JSON object with an "enhanced_text" field containing the improved text
            5. Always respond with valid JSON format
            """],
            ["role": "user", "content": "Please enhance this transcribed text and return as JSON: \"\(text)\""]
        ]
        
        let requestBody = [
            "model": enhancementModel,
            "messages": messages,
            "response_format": ["type": "json_object"]
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        return request
    }
    
    func validationRequest(apiKey: String) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Authorization")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = [
            "model": validationModel,
            "messages": [
                ["role": "user", "content": "hello world"]
            ],
            "response_format": ["type": "text"],
            "verbosity": "medium",
            "reasoning_effort": "medium",
            "store": false
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        return request
    }
    
    func parseTranscriptionResponse(data: Data) throws -> String {
        struct TranscriptionResponse: Codable {
            let text: String
        }
        
        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return response.text
    }
    
    func parseEnhancementResponse(data: Data) throws -> String {
        struct ChatResponse: Codable {
            let choices: [ChatChoice]
        }
        
        struct ChatChoice: Codable {
            let message: ChatMessage
        }
        
        struct ChatMessage: Codable {
            let content: String
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let messageContent = chatResponse.choices.first?.message.content else {
            throw APIError.noResponse
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
    }
    
    func parseValidationResponse(data: Data) throws -> Bool {
        // For validation, we just check if we got any valid response
        // The actual content doesn't matter, just that the API call succeeded
        return true
    }
}

// MARK: - Groq Configuration

struct GroqConfig: ProviderConfig {
    let provider: APIProvider = .groq
    let baseURL: String = "https://api.groq.com/openai/v1"
    let transcriptionModel: String = "whisper-large-v3-turbo"
    let enhancementModel: String = "openai/gpt-oss-120b"
    let validationModel: String = "openai/gpt-oss-120b"
    
    func transcriptionRequest(audioURL: URL, apiKey: String) throws -> URLRequest {
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
        body.append("\(transcriptionModel)\r\n".data(using: .utf8)!)
        
        // Add temperature parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0\r\n".data(using: .utf8)!)
        
        // Add response_format parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        
        // Add file parameter
        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        return request
    }
    
    func enhancementRequest(text: String, context: String, apiKey: String) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = [
            ["role": "user", "content": """
            You are a text enhancement assistant. Your task is to improve transcribed speech while maintaining its original meaning and intent.
            
            User's context: \(context)
            
            Instructions:
            1. Fix grammar, punctuation, and spelling errors
            2. Improve clarity and readability
            3. Maintain the original tone and meaning
            4. Return only the enhanced text, no additional formatting or explanation
            
            Transcribed text to enhance: "\(text)"
            """]
        ]
        
        let requestBody = [
            "model": enhancementModel,
            "messages": messages,
            "temperature": 1,
            "max_completion_tokens": 8192,
            "top_p": 1,
            "reasoning_effort": "medium"
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        return request
    }
    
    func validationRequest(apiKey: String) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "model": validationModel,
            "messages": [
                ["role": "user", "content": "hello world"]
            ],
            "temperature": 1,
            "max_completion_tokens": 100,
            "top_p": 1,
            "reasoning_effort": "medium"
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        return request
    }
    
    func parseTranscriptionResponse(data: Data) throws -> String {
        struct GroqTranscriptionResponse: Codable {
            let text: String
            let segments: [TranscriptionSegment]?
        }
        
        struct TranscriptionSegment: Codable {
            let text: String
            let start: Double
            let end: Double
        }
        
        let response = try JSONDecoder().decode(GroqTranscriptionResponse.self, from: data)
        return response.text
    }
    
    func parseEnhancementResponse(data: Data) throws -> String {
        struct ChatResponse: Codable {
            let choices: [ChatChoice]
        }
        
        struct ChatChoice: Codable {
            let message: ChatMessage
        }
        
        struct ChatMessage: Codable {
            let content: String
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let messageContent = chatResponse.choices.first?.message.content else {
            throw APIError.noResponse
        }
        
        return messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parseValidationResponse(data: Data) throws -> Bool {
        // For validation, we just check if we got any valid response
        return true
    }
}

// MARK: - Provider Factory

struct ProviderConfigFactory {
    static func create(_ provider: APIProvider) -> ProviderConfig {
        switch provider {
        case .openai:
            return OpenAIConfig()
        case .groq:
            return GroqConfig()
        }
    }
}

// MARK: - Error Types

enum APIError: Error, LocalizedError {
    case invalidProvider
    case missingAPIKey
    case invalidResponse
    case apiError(Int, String)
    case fileError(String)
    case encodingError(String)
    case decodingError(String)
    case noResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidProvider:
            return "Invalid API provider selected"
        case .missingAPIKey:
            return "API key is missing"
        case .invalidResponse:
            return "Invalid response from API"
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