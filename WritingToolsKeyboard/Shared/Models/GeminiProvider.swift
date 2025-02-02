import Foundation

struct GeminiConfig: Codable {
    var apiKey: String
    var modelName: String
}

enum GeminiModel: String, CaseIterable {
    case flash8b = "gemini-1.5-flash-8b-latest"
    case flash   = "gemini-1.5-flash-latest"
    case pro     = "gemini-1.5-pro-latest"
    case twoflash = "gemini-2.0-flash-exp"
    
    var displayName: String {
        switch self {
        case .flash8b: return "Gemini 1.5 Flash 8B (fast)"
        case .flash:   return "Gemini 1.5 Flash (fast & more intelligent, recommended)"
        case .pro:     return "Gemini 1.5 Pro (very intelligent, but slower & lower rate limit)"
        case .twoflash: return "Gemini 2.0 Flash (extremely intelligent & fast, recommended)"
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
        
        // Run OCR on any attached images.
        var ocrExtractedText = ""
        for image in images {
            do {
                let recognized = try await OCRManager.shared.performOCR(on: image)
                if !recognized.isEmpty {
                    ocrExtractedText += recognized + "\n"
                }
            } catch {
                print("OCR error (Mistral): \(error.localizedDescription)")
            }
        }
        
        // Truncate user prompt to avoid extremely large requests
        let truncatedPrompt = userPrompt.count > 8000 ? String(userPrompt.prefix(8000)) : userPrompt
        
        // Combine system prompt and user prompt
        let combinedUserPrompt = ocrExtractedText.isEmpty ? truncatedPrompt : "\(truncatedPrompt)\n\nOCR Extracted Text:\n\(ocrExtractedText)"
        let finalPrompt = systemPrompt.map { "\($0)\n\n\(combinedUserPrompt)" } ?? combinedUserPrompt
        
        
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
