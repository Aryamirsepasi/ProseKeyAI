import SwiftUI

@MainActor
class ChatMessageHandler {
    static func processMessage(content: String, thread: Thread, appState: AppState, llm: LocalLLMProvider, appManager: AppManager, currentProvider: String) async -> String {
        if currentProvider == "local" {
            if let modelName = appManager.currentModelName {
                // Generate with local LLM
                do {
                    return try await llm.generate(
                                       modelName: modelName,
                                       thread: thread,
                                       systemPrompt: appManager.systemPrompt
                                   )
                } catch {
                    return "Local model error: \(error.localizedDescription)"
                }
            }
            return "No local model selected. Please install a model in settings."
        } else {
            // Use online providers
            do {
                let response = try await appState.activeProvider.processText(
                    systemPrompt: appManager.systemPrompt,
                    userPrompt: content
                )
                return response
            } catch {
                return "Error: \(error.localizedDescription)"
            }
        }
    }
}

// Extension to local LLM for generating from a thread
extension LocalLLMProvider {
    func generate(modelName: String, thread: Thread, systemPrompt: String) async throws -> String {
        running = true
        cancelled = false
        output = ""
        
        do {
            let container = try await load(modelName: modelName)
            let promptHistory = container.configuration.getPromptHistory(thread: thread, systemPrompt: systemPrompt)
            
            // Combine into a text prompt
            let textPrompt = promptHistory.map { "\($0["role"] ?? ""): \($0["content"] ?? "")" }
                                           .joined(separator: "\n\n")
            
            return try await processText(systemPrompt: nil, userPrompt: textPrompt)
        } catch {
            running = false
            throw error
        }
    }
}
