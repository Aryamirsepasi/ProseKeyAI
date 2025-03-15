import Foundation

struct GeminiConfig: Codable {
    var apiKey: String
    var modelName: String
}

enum GeminiModel: String, CaseIterable {
    case twofashlite = "gemini-2.0-flash-lite-preview"
    case twoflash = "gemini-2.0-flash-exp"
    case twoflashthinking = "gemini-2.0-flash-thinking-exp-01-21"
    case twopro = "gemini-2.0-pro-exp-02-05"
    
    var displayName: String {
        switch self {
        case .twofashlite: return "Gemini 2.0 Flash Lite (intelligent | very fast | 30 uses/min)"
        case .twoflash: return "Gemini 2.0 Flash (very intelligent | fast | 15 uses/min)"
        case .twoflashthinking: return "Gemini 2.0 Flash Thinking (most intelligent | slow | 10 uses/min)"
        case .twopro: return "Gemini 2.0 Pro (most intelligent | slow | 2 uses/min)"
            
        }
    }
}

class GeminiProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    
    var config: GeminiConfig
    private var currentTask: URLSessionDataTask?
    
    // Use of ephemeral session to reduce memory/disk usage
    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 20
        return URLSession(configuration: configuration)
    }()
    
    init(config: GeminiConfig) {
        self.config = config
    }
    
    func processText(systemPrompt: String? = "You are a helpful writing assistant.",
                     userPrompt: String,
                     images: [Data],
                     streaming: Bool = false) async throws -> String {        guard !config.apiKey.isEmpty else {
        throw AIError.missingAPIKey
    }
        
        
        // Truncate user prompt to avoid extremely large requests
        let truncatedPrompt = userPrompt.count > 8000 ? String(userPrompt.prefix(8000)) : userPrompt
        
        let finalPrompt = systemPrompt.map { "\($0)\n\n\(truncatedPrompt)" } ?? truncatedPrompt
        
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(config.modelName):generateContent?key=\(config.apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIError.serverError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": finalPrompt]]]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        isProcessing = true
        let (data, response) = try await urlSession.data(for: request)
        isProcessing = false
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.serverError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AIError.invalidResponse
        }
        
        return text
    }
    
    func cancel() {
        currentTask?.cancel()
        isProcessing = false
    }
}
