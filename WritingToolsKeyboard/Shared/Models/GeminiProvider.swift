import Foundation
import AIProxy

struct GeminiConfig: Codable, Sendable {
    var apiKey: String
    var modelName: String
}

enum GeminiModel: String, CaseIterable {
    case flashlite = "gemini-flash-lite-latest"
    case flash = "gemini-flash-latest"
    case prevflash = "gemini-3-flash-preview"
    case pro = "gemini-3-pro-preview"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .flashlite: return "Gemini 2.5 Flash Lite"
        case .flash: return "Gemini 2.5 Flash"
        case .prevflash: return "Gemini 3.0 Flash"
        case .pro: return "Gemini 3.0 Pro"
        case .custom: return "Custom"
        }
    }
}

@MainActor
class GeminiProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    private let config: GeminiConfig
    private var currentTask: Task<String, Error>?
    
    init(config: GeminiConfig) {
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
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key is missing."])
        }
        
        let config = self.config
        let task = Task.detached(priority: .userInitiated) { () throws -> String in
            try Task.checkCancellation()
            
            let geminiService = AIProxy.geminiDirectService(unprotectedAPIKey: config.apiKey)
            
            let finalPrompt = systemPrompt.map { "\($0)\n\n\(userPrompt)" } ?? userPrompt
            
            var parts: [GeminiGenerateContentRequestBody.Content.Part] = [.text(finalPrompt)]
            
            for imageData in images {
                parts.append(.inline(data: imageData, mimeType: "image/jpeg"))
            }
            
            let requestBody = GeminiGenerateContentRequestBody(
                contents: [.init(parts: parts)],
                safetySettings: [
                    .init(category: .dangerousContent, threshold: .none),
                    .init(category: .harassment, threshold: .none),
                    .init(category: .hateSpeech, threshold: .none),
                    .init(category: .sexuallyExplicit, threshold: .none),
                    .init(category: .civicIntegrity, threshold: .none)
                ]
            )
            
            do {
                let response = try await geminiService.generateContentRequest(body: requestBody, model: config.modelName, secondsToWait: 60)
                
                /*if let usage = response.usageMetadata {
                    print("""
                         Gemini API Usage:
                         
                          \(usage.promptTokenCount ?? 0) prompt tokens
                          \(usage.candidatesTokenCount ?? 0) candidate tokens
                          \(usage.totalTokenCount ?? 0) total tokens
                         """)
                }*/
                
                for part in response.candidates?.first?.content?.parts ?? [] {
                    switch part {
                    case .text(let text):
                        return text
                    case .functionCall(name: let functionName, args: let arguments):
                        print("Function call received: \(functionName) with args: \(arguments ?? [:])")
                    case .inlineData(mimeType: _, base64Data: _):
                        print("Image generation?")
                    }
                }
                
                throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text content in response."])
                
            } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
                print("AIProxy error (\(statusCode)): \(responseBody)")
                throw NSError(domain: "GeminiAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"])
            } catch {
                print("Gemini request failed: \(error.localizedDescription)")
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
