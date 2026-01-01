import Foundation
import AIProxy

struct AnthropicConfig: Codable, Sendable {
    var apiKey: String
    var model: String
    
    static let defaultModel = "claude-3-5-sonnet-20240620"
}

enum AnthropicModel: String, CaseIterable {
    case claude3Haiku = "claude-3-7-sonnet-20250219"
    case claude3Sonnet = "claude-sonnet-4-20250514"
    case claude3Opus = "claude-opus-4-20250514"
    case custom
    
    var displayName: String {
        switch self {
        case .claude3Haiku: return "Claude 3.7 Sonnet"
        case .claude3Sonnet: return "Claude 4.0 Sonnet (Best for Most Users)"
        case .claude3Opus: return "Claude 4.0 Opus (Most Capable, Expensive)"
        case .custom: return "Custom"
        }
    }
}

@MainActor
class AnthropicProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    
    private let config: AnthropicConfig
    private var currentTask: Task<String, Error>?
    
    init(config: AnthropicConfig) {
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
                domain: "AnthropicAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "API key is missing."]
            )
        }
        
        let config = self.config
        let task = Task.detached(priority: .userInitiated) { () throws -> String in
            try Task.checkCancellation()
            
            let anthropicService = AIProxy.anthropicDirectService(unprotectedAPIKey: config.apiKey)
            
            // Compose messages array
            var messages: [AnthropicInputMessage] = []
            
            var userContent: [AnthropicInputContent] = [.text(userPrompt)]
            for imageData in images {
                userContent.append(
                    .image(mediaType: AnthropicImageMediaType.jpeg, data: imageData.base64EncodedString())
                )
            }
            messages.append(
                AnthropicInputMessage(content: userContent, role: .user)
            )
            
            let requestBody = AnthropicMessageRequestBody(
                maxTokens: 1024,
                messages: messages,
                model: config.model.isEmpty ? AnthropicConfig.defaultModel : config.model,
                system: systemPrompt
            )
            
            do {
                let response = try await anthropicService.messageRequest(body: requestBody)
                
                for content in response.content {
                    switch content {
                    case .text(let message):
                        return message
                    case .toolUse(id: _, name: let toolName, input: let toolInput):
                        print("Anthropic tool use: \(toolName) input: \(toolInput)")
                    }
                }
                throw NSError(
                    domain: "AnthropicAPI",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No text content in response."]
                )
            } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
                print("Anthropic error (\(statusCode)): \(responseBody)")
                throw NSError(
                    domain: "AnthropicAPI",
                    code: statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"]
                )
            } catch {
                print("Anthropic request failed: \(error.localizedDescription)")
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
