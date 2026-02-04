import Foundation
import UIKit
import AIProxy

struct OpenRouterConfig: Codable, Sendable {
    var apiKey: String
    var model: String
    static let defaultModel = "moonshotai/kimi-k2.5"
}

enum OpenRouterModel: String, CaseIterable {
    case kimi = "moonshotai/kimi-k2.5"
    case geminiflash = "google/gemini-3-flash-preview"
    case minimax = "minimax/minimax-m2.1"
    case mistralsmall = "mistralai/mistral-small-creative"
    case custom
    
    var displayName: String {
        switch self {
        case .kimi: return "Kimi K2.5"
        case .geminiflash: return "Gemini 3 Flash"
        case .minimax: return "MiniMax M2.1"
        case .mistralsmall: return "Mistral Small Creative"
        case .custom: return "Custom"
        }
    }
}

@MainActor
class OpenRouterProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    
    private let config: OpenRouterConfig
    private var currentTask: Task<String, Error>?
    
    init(config: OpenRouterConfig) {
        self.config = config
    }
    
    func processText(
        systemPrompt: String? = "You are a helpful writing assistant.",
        userPrompt: String,
        images: [Data] = [],
        streaming: Bool = false
    ) async throws -> String {
        currentTask?.cancel()
        isProcessing = true
        defer {
            isProcessing = false
            currentTask = nil
        }
        
        guard !config.apiKey.isEmpty else {
            throw NSError(
                domain: "OpenRouterAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "API key is missing."]
            )
        }
        
        let config = self.config
        let task = Task.detached(priority: .userInitiated) { () throws -> String in
            try Task.checkCancellation()
            
            let openRouterService = AIProxy.openRouterDirectService(unprotectedAPIKey: config.apiKey)
            
            // Compose messages
            var messages: [OpenRouterChatCompletionRequestBody.Message] = []
            if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
                messages.append(.system(content: .text(systemPrompt)))
            }
            
            if images.isEmpty {
                messages.append(.user(content: .text(userPrompt)))
            } else {
                var parts: [OpenRouterChatCompletionRequestBody.Message.UserContent.Part] = [.text(userPrompt)]
                for imageData in images {
                    if let uiImage = UIImage(data: imageData),
                       let imageURL = AIProxy.encodeImageAsURL(image: uiImage, compressionQuality: 0.8) {
                        parts.append(.imageURL(imageURL))
                    }
                }
                messages.append(.user(content: .parts(parts)))
            }
            
            let modelName = config.model.isEmpty ? OpenRouterConfig.defaultModel : config.model
            
            let requestBody = OpenRouterChatCompletionRequestBody(
                messages: messages,
                models: [modelName],
                route: .fallback
            )
            
            do {
                if streaming {
                    var compiledResponse = ""
                    let stream = try await openRouterService.streamingChatCompletionRequest(body: requestBody)
                    for try await chunk in stream {
                        try Task.checkCancellation()
                        if let content = chunk.choices.first?.delta.content {
                            compiledResponse += content
                        }
                    }
                    return compiledResponse
                } else {
                    let response = try await openRouterService.chatCompletionRequest(body: requestBody)
                    try Task.checkCancellation()
                    return response.choices.first?.message.content ?? ""
                }
            } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
                print("OpenRouter error (\(statusCode)): \(responseBody)")
                throw NSError(
                    domain: "OpenRouterAPI",
                    code: statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"]
                )
            } catch {
                print("OpenRouter request failed: \(error.localizedDescription)")
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
