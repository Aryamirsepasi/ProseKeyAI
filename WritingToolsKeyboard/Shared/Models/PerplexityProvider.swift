//
//  PerplexityProvider.swift
//  ProseKey AI
//
//  Created by Arya Mirsepasi on 11.09.25.
//

import Foundation
import AIProxy

struct PerplexityConfig: Codable {
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
    
    var config: PerplexityConfig
    private var aiProxyService: PerplexityService?
    private var currentTask: Task<Void, Never>?
    
    init(config: PerplexityConfig) {
        self.config = config
        setupAIProxyService()
    }
    
    private func setupAIProxyService() {
        guard !config.apiKey.isEmpty else { return }
        aiProxyService = AIProxy.perplexityDirectService(
            unprotectedAPIKey: config.apiKey
        )
    }
    
    func processText(
        systemPrompt: String? = "You are a helpful writing assistant.",
        userPrompt: String,
        images: [Data] = [],
        streaming: Bool = false
    ) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        guard !config.apiKey.isEmpty else {
            throw NSError(
                domain: "PerplexityAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "API key is missing."]
            )
        }
        
        if aiProxyService == nil { setupAIProxyService() }
        guard let service = aiProxyService else {
            throw NSError(
                domain: "PerplexityAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AIProxy service."]
            )
        }
        
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
                    if Task.isCancelled { break }
                    if let delta = chunk.choices.first?.delta?.content {
                        compiled += delta
                    }
                }
                return compiled
            } else {
                let response = try await service.chatCompletionRequest(
                    body: body                )
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
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }
}
