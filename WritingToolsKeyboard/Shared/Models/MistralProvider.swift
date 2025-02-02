import Foundation
struct MistralConfig: Codable {
    var apiKey: String
    var baseURL: String
    var model: String
    
    static let defaultBaseURL = "https://api.mistral.ai/v1"
    static let defaultModel = "mistral-small-latest"
}
enum MistralModel: String, CaseIterable {
    case mistralSmall = "mistral-small-latest"
    case mistralMedium = "mistral-medium-latest"
    case mistralLarge = "mistral-large-latest"
    
    var displayName: String {
        switch self {
        case .mistralSmall: return "Mistral Small (Fast)"
        case .mistralMedium: return "Mistral Medium (Balanced)"
        case .mistralLarge: return "Mistral Large (Most Capable)"
        }
    }
}

class MistralProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    var config: MistralConfig
    
    init(config: MistralConfig) {
        self.config = config
    }
    
    func processText(systemPrompt: String? = "You are a helpful writing assistant.",
                     userPrompt: String,
                     images: [Data],
                     streaming: Bool = false) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        guard !config.apiKey.isEmpty else {
            throw NSError(domain: "MistralAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key is missing."])
        }
        
        let baseURL = config.baseURL.isEmpty ? MistralConfig.defaultBaseURL : config.baseURL
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw NSError(domain: "MistralAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."])
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
        
        let combinedUserPrompt = ocrExtractedText.isEmpty ? userPrompt : "\(userPrompt)\n\nOCR Extracted Text:\n\(ocrExtractedText)"
        
        var messages: [[String: Any]] = []
        if let systemPrompt = systemPrompt {
            messages.append(["role": "system", "content": systemPrompt])
        }
        messages.append(["role": "user", "content": combinedUserPrompt])
        
        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": messages
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "MistralAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server returned an error."])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "MistralAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response."])
        }
        
        return content
    }
    
    func cancel() {
        isProcessing = false
    }
}
