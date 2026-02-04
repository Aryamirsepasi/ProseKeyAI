import Foundation
import AIProxy

struct AnthropicConfig: Codable, Sendable {
    var apiKey: String
    var model: String
    
    static let defaultModel = "claude-haiku-4-5"
}

enum AnthropicModel: String, CaseIterable {
    case claude3Haiku = "claude-haiku-4-5"
    case claude3Sonnet = "claude-sonnet-4-5"
    case claude3Opus = "claude-opus-4-5"
    case custom
    
    var displayName: String {
        switch self {
        case .claude3Haiku: return "Claude 4.5 Haiku"
        case .claude3Sonnet: return "Claude 4.5 Sonnet (Best for Most Users)"
        case .claude3Opus: return "Claude 4.5 Opus (Most Capable, Expensive)"
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
            var userBlocks: [AnthropicContentBlockParam] = [
                .textBlock(AnthropicTextBlockParam(text: userPrompt))
            ]
            for imageData in images {
                let imageBlock = AnthropicImageBlockParam(
                    source: .base64(
                        data: imageData.base64EncodedString(),
                        mediaType: .jpeg
                    )
                )
                userBlocks.append(.imageBlock(imageBlock))
            }
            let messages: [AnthropicMessageParam] = [
                AnthropicMessageParam(content: .blocks(userBlocks), role: .user)
            ]
            
            let systemPromptParam = systemPrompt.map { AnthropicSystemPrompt.text($0) }
            let requestBody = AnthropicMessageRequestBody(
                maxTokens: 1024,
                messages: messages,
                model: config.model.isEmpty ? AnthropicConfig.defaultModel : config.model,
                system: systemPromptParam
            )
            
            do {
                let response = try await anthropicService.messageRequest(
                    body: requestBody,
                    secondsToWait: 60
                )
                
                for content in response.content {
                    switch content {
                    case .textBlock(let textBlock):
                        return textBlock.text
                    case .toolUseBlock(let toolUseBlock):
                        #if DEBUG
                        print("Anthropic tool use: \(toolUseBlock.name) input: \(toolUseBlock.input)")
                        #endif
                    case .futureProof:
                        continue
                    case .thinkingBlock,
                         .redactedThinkingBlock,
                         .serverToolUseBlock,
                         .webSearchToolResultBlock:
                        continue
                    }
                }
                throw NSError(
                    domain: "AnthropicAPI",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No text content in response."]
                )
            } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
                #if DEBUG
                print("Anthropic error (\(statusCode)): \(responseBody)")
                #endif
                throw NSError(
                    domain: "AnthropicAPI",
                    code: statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"]
                )
            } catch {
                #if DEBUG
                print("Anthropic request failed: \(error.localizedDescription)")
                #endif
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
