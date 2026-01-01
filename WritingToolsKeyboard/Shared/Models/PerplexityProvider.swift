//
//  PerplexityProvider.swift
//  ProseKey AI
//
//  Created by Arya Mirsepasi on 11.09.25.
//

import Foundation
import AIProxy

struct PerplexityConfig: Codable, Sendable {
    var apiKey: String
    var model: String
    
    static let defaultModel = "sonar"
}

enum PerplexityModel: String, CaseIterable {
    case sonarSmall = "sonar"
    case sonarLarge = "sonar-pro"
    
    var displayName: String {
        switch self {
        case .sonarSmall: return "Sonar"
        case .sonarLarge: return "Sonar Pro"
        }
    }
}

@MainActor
final class PerplexityProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    
    private let config: PerplexityConfig
    private var currentTask: Task<String, Error>?
    
    init(config: PerplexityConfig) {
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
                domain: "PerplexityAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "API key is missing."]
            )
        }
        
        let config = self.config
        let task = Task.detached(priority: .userInitiated) { () throws -> String in
            try Task.checkCancellation()
            
            let service = AIProxy.perplexityDirectService(
                unprotectedAPIKey: config.apiKey
            )
            
            // Compose a single user prompt (Perplexity's sample shows .user only).
            var prompt = userPrompt
            if let sys = systemPrompt, !sys.isEmpty {
                prompt = "\(sys)\n\nUser: \(userPrompt)"
            }
            
            // Optional: OCR any images and append the extracted text
            if !images.isEmpty {
                let ocrText = await OCRManager.shared.extractText(from: images)
                if !ocrText.isEmpty {
                    prompt += "\n\n[Extracted text from attached images]\n\(ocrText)"
                }
            }
            
            let body = PerplexityChatCompletionRequestBody(
                messages: [.user(content: prompt)],
                model: config.model
            )
            
            do {
                if streaming {
                    var compiled = ""
                    let stream = try await service.streamingChatCompletionRequest(
                        body: body
                    )
                    for try await chunk in stream {
                        try Task.checkCancellation()
                        if let delta = chunk.choices.first?.delta?.content {
                            compiled += delta
                        }
                    }
                    return compiled
                } else {
                    let response = try await service.chatCompletionRequest(
                        body: body
                    )
                    try Task.checkCancellation()
                    return response.choices.first?.message?.content ?? ""
                }
            } catch AIProxyError.unsuccessfulRequest(let status, let responseBody) {
                print("Perplexity error (\(status)): \(responseBody)")
                throw NSError(
                    domain: "PerplexityAPI",
                    code: status,
                    userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"]
                )
            } catch {
                print("Perplexity request failed: \(error.localizedDescription)")
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
