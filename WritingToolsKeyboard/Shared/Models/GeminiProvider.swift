import Foundation

struct GeminiConfig: Codable {
    var apiKey: String
    var modelName: String
}

enum GeminiModel: String, CaseIterable {
    case flash8b = "gemini-1.5-flash-8b-latest"
    case flash   = "gemini-1.5-flash-latest"
    case pro     = "gemini-1.5-pro-latest"
    
    var displayName: String {
        switch self {
        case .flash8b: return "Gemini 1.5 Flash 8B (fast)"
        case .flash:   return "Gemini 1.5 Flash (fast & more intelligent, recommended)"
        case .pro:     return "Gemini 1.5 Pro (very intelligent, but slower & lower rate limit)"
        }
    }
}

class GeminiProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    private var config: GeminiConfig
    private var currentTask: URLSessionDataTask?
    
    init(config: GeminiConfig) {
        self.config = config
    }
    
    func processText(systemPrompt: String? = nil, userPrompt: String) async throws -> String {
        guard !config.apiKey.isEmpty else {
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
