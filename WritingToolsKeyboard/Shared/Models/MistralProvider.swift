import Foundation
import AIProxy


struct MistralConfig: Codable, Sendable {
    var apiKey: String
    var model: String
    
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

@MainActor
class MistralProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    private let config: MistralConfig
    private var currentTask: Task<String, Error>?
    
    init(config: MistralConfig) {
        self.config = config
    }
    
    func processText(systemPrompt: String? = "You are a helpful writing assistant.", userPrompt: String, images: [Data] = [], streaming: Bool = false) async throws -> String {
        currentTask?.cancel()
        isProcessing = true
        defer {
            isProcessing = false
            currentTask = nil
        }
        
        guard !config.apiKey.isEmpty else {
            throw NSError(domain: "MistralAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key is missing."])
        }
        
        let config = self.config
        let task = Task.detached(priority: .userInitiated) { () throws -> String in
            try Task.checkCancellation()
            
            let mistralService = AIProxy.mistralDirectService(unprotectedAPIKey: config.apiKey)
            
            var messages: [MistralChatCompletionRequestBody.Message] = []
            
            if let systemPrompt = systemPrompt {
                messages.append(.system(content: systemPrompt))
            }
            
            messages.append(.user(content: userPrompt))
            
            do {
                if streaming {
                    var compiledResponse = ""
                    let stream = try await mistralService.streamingChatCompletionRequest(body: .init(
                        messages: messages,
                        model: config.model
                    ), secondsToWait: 60)
                    
                    for try await chunk in stream {
                        try Task.checkCancellation()
                        if let content = chunk.choices.first?.delta.content {
                            compiledResponse += content
                        }
                        if let usage = chunk.usage {
                            print("""
                                    Used:
                                     \(usage.promptTokens ?? 0) prompt tokens
                                     \(usage.completionTokens ?? 0) completion tokens
                                     \(usage.totalTokens ?? 0) total tokens
                                    """)
                        }
                    }
                    return compiledResponse
                    
                } else {
                    let response = try await mistralService.chatCompletionRequest(body: .init(
                        messages: messages,
                        model: config.model,
                    ), secondsToWait: 60)
                    
                    /*if let usage = response.usage {
                        print("""
                                Used:
                                 \(usage.promptTokens ?? 0) prompt tokens
                                 \(usage.completionTokens ?? 0) completion tokens
                                 \(usage.totalTokens ?? 0) total tokens
                                """)
                    }*/
                    
                    try Task.checkCancellation()
                    return response.choices.first?.message.content ?? ""
                }
                
            } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
                print("Received non-200 status code: \(statusCode) with response body: \(responseBody)")
                throw NSError(domain: "MistralAPI",
                              code: statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"])
            } catch {
                print("Could not create mistral chat completion: \(error.localizedDescription)")
                throw error
            }
        }
        
        currentTask = task
        return try await task.value
    }
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }
}
