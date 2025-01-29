import Foundation

struct OpenAIConfig: Codable {
    var apiKey: String
    var baseURL: String
    var organization: String?
    var project: String?
    var model: String
    
    static let defaultBaseURL = "https://api.openai.com/v1"
    static let defaultModel   = "gpt-4o"
}

enum OpenAIModel: String, CaseIterable {
    case gpt4        = "gpt-4"
    case gpt35Turbo  = "gpt-3.5-turbo"
    case gpt4o       = "gpt-4o"
    case gpt4oMini   = "gpt-4o-mini"
    
    var displayName: String {
        switch self {
        case .gpt4:       return "GPT-4 (Most Capable)"
        case .gpt35Turbo: return "GPT-3.5 Turbo (Faster)"
        case .gpt4o:      return "GPT-4o (Optimized)"
        case .gpt4oMini:  return "GPT-4o Mini (Lightweight)"
        }
    }
}

@MainActor
class OpenAIProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    
     var config: OpenAIConfig
    private var currentTask: URLSessionDataTask?
    
    // Use of ephemeral session to reduce memory/disk usage
    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 20
        return URLSession(configuration: configuration)
    }()
    
    init(config: OpenAIConfig) {
        self.config = config
    }
    
    func processText(systemPrompt: String? = nil, userPrompt: String) async throws -> String {
        guard !config.apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }
        
        let truncatedUserPrompt = userPrompt.count > 8000 ? String(userPrompt.prefix(8000)) : userPrompt
        
        let baseURL = config.baseURL.isEmpty ? OpenAIConfig.defaultBaseURL : config.baseURL
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.serverError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        if let organization = config.organization {
            request.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
        }
        
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt ?? "You are a helpful writing assistant."],
            ["role": "user", "content": truncatedUserPrompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "temperature": 0.7
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
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: String],
              let content = message["content"] else {
            throw AIError.invalidResponse
        }
        
        return content
    }
    
    func cancel() {
        currentTask?.cancel()
        isProcessing = false
    }
}
